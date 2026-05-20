import { onCall } from 'firebase-functions/v2/https';
import { geminiModel } from '../config/gemini';

export const rankProviders = onCall(async (request) => {
    try {
        const { providers, isUrgent } = request.data;
        if (!providers || !Array.isArray(providers)) {
            throw new Error("Missing or invalid providers array");
        }

        if (providers.length === 0) {
             return { success: true, data: { rankedProviders: [], reasoning: "No providers found.", rankingLog: "Empty list" }, log: "No providers to rank." };
        }

        const prompt = `You are a provider ranking agent for HireIn. Score and rank these service providers for a customer request.
  
Providers: ${JSON.stringify(providers)}
Is Urgent: ${isUrgent}

Scoring criteria:
- Distance score (40%): closer = higher score
- Rating score (30%): higher rating = higher score  
- On-time score (20%): higher = better
- Risk score (10%): lower risk = better (inverse)
- If urgent: heavily weight distance and isOnline status

Return ONLY valid JSON:
{
  "rankedProviders": [array of providers with added 'totalScore' and 'scoreBreakdown' fields],
  "reasoning": "string (explain why top provider was chosen over others)",
  "rankingLog": "string (full scoring table)"
}`;

        const result = await geminiModel.generateContent(prompt);
        const responseText = result.response.text();
        
        const jsonStr = responseText.replace(/```json/g, '').replace(/```/g, '').trim();
        const parsedData = JSON.parse(jsonStr);

        const log = `Agent 3 (Ranking Engine)\nRanked ${parsedData.rankedProviders.length} providers.\nReasoning: ${parsedData.reasoning}\nLog: ${parsedData.rankingLog}`;

        return {
            success: true,
            data: parsedData,
            log: log
        };
    } catch (error: any) {
        console.error("Error in rankProviders:", error);
        return {
            success: false,
            error: error.message
        };
    }
});
