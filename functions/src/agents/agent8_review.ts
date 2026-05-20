import { onCall } from 'firebase-functions/v2/https';
import { geminiModel } from '../config/gemini';
import { db } from '../config/firebase';

export const updateReviewAndBadges = onCall(async (request) => {
    try {
        const { providerId, rating, customerBadges } = request.data;
        if (!providerId || rating === undefined) {
            throw new Error("Missing providerId or rating");
        }

        const providerRef = db.collection('providers').doc(providerId);
        const providerSnap = await providerRef.get();
        if (!providerSnap.exists) {
            throw new Error("Provider not found");
        }
        
        const providerData = providerSnap.data() || {};

        const prompt = `You are a badge management agent for HireIn. A customer just rated a provider.
  
Provider current data: ${JSON.stringify(providerData)}
New rating: ${rating}/5
Customer badge chips selected: ${JSON.stringify(customerBadges || [])}

Positive badges to potentially award: Top Rated (avg > 4.5), Verified (always if verified), Affordable (if 'Affordable' chip selected 3+ times), On Time (onTimeScore > 0.8), Expert Level (skillLevel == expert AND rating > 4.3)

Negative tags (not shown publicly but affect ranking): Expensive, Late, Unprofessional

Calculate new average rating, update badge list, update negative tags.

Return ONLY valid JSON:
{
  "newRating": number,
  "newReviewCount": number,
  "badgesToAdd": string[],
  "badgesToRemove": string[],
  "negativeTagsToAdd": string[],
  "riskScoreAdjustment": number (-0.1 to +0.1),
  "reasoning": "string"
}`;

        const apiKey = process.env.GEMINI_API_KEY || '';
        let responseText = '';
        
        if (!apiKey) {
            console.warn("GEMINI_API_KEY is missing. Running Agent 8 in Fallback Algorithmic Mode.");
            const mockParsedData = {
                newRating: rating,
                newReviewCount: (providerData.reviewCount || 0) + 1,
                badgesToAdd: customerBadges || [],
                badgesToRemove: [],
                negativeTagsToAdd: [],
                riskScoreAdjustment: 0,
                reasoning: "Fallback mock executed for review."
            };
            responseText = JSON.stringify(mockParsedData);
        } else {
            const result = await geminiModel.generateContent(prompt);
            responseText = result.response.text();
        }
        
        const jsonStr = responseText.replace(/```json/g, '').replace(/```/g, '').trim();
        const parsedData = JSON.parse(jsonStr);

        const log = `Agent 8 (Review)\nNew Rating: ${parsedData.newRating}\nBadges Added: ${parsedData.badgesToAdd.join(', ')}\nReasoning: ${parsedData.reasoning}`;

        await providerRef.update({
            rating: parsedData.newRating,
            reviewCount: parsedData.newReviewCount,
            riskScore: (providerData.riskScore || 0) + parsedData.riskScoreAdjustment
        });

        return {
            success: true,
            isFallback: !apiKey,
            data: parsedData,
            log: log
        };
    } catch (error: any) {
        console.error("Error in updateReviewAndBadges:", error);
        return {
            success: false,
            error: error.message
        };
    }
});
