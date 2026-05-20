import { onCall } from 'firebase-functions/v2/https';
import { geminiModel } from '../config/gemini';

export const selectMatch = onCall(async (request) => {
    try {
        const { rankedProviders, pricingResults } = request.data;
        if (!rankedProviders || !pricingResults) {
            throw new Error("Missing rankedProviders or pricingResults");
        }

        const dataPayload = {
            rankedProviders,
            pricingResults
        };

        const prompt = `You are the final matchmaker agent for HireIn. Select the best provider for this customer and write a clear reasoning summary that will be shown to the customer.
  
Ranked providers with pricing: ${JSON.stringify(dataPayload)}

Select the winner (rank 1 unless pricing makes rank 2 significantly better value).
Select 2-3 alternatives.

Return ONLY valid JSON:
{
  "winner": { ...provider object, pricing: {...} },
  "alternatives": [array of 2-3 providers with pricing],
  "reasoningSummary": "string (2-3 sentences in simple language explaining why this provider was chosen — mention distance, rating, price. Write in English but keep it simple)",
  "reasoning": "string (internal detailed reasoning)"
}`;

        const result = await geminiModel.generateContent(prompt);
        const responseText = result.response.text();
        
        const jsonStr = responseText.replace(/```json/g, '').replace(/```/g, '').trim();
        const parsedData = JSON.parse(jsonStr);

        const log = `Agent 5 (Matchmaker)\nWinner: ${parsedData.winner?.id}\nSummary: ${parsedData.reasoningSummary}`;

        return {
            success: true,
            data: parsedData,
            log: log
        };
    } catch (error: any) {
        console.error("Error in selectMatch:", error);
        return {
            success: false,
            error: error.message
        };
    }
});
