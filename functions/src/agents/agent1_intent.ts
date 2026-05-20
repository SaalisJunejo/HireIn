import { onCall } from 'firebase-functions/v2/https';
import { geminiModel } from '../config/gemini';

export const extractIntent = onCall(async (request) => {
    try {
        const { userInput, userId } = request.data;
        if (!userInput || !userId) {
            throw new Error("Missing userInput or userId");
        }

        const prompt = `You are an AI agent for HireIn, a service booking app in Pakistan. Parse this user request and extract structured information. The input may be in Urdu, Roman Urdu, English, or mixed.
  
User input: ${userInput}
  
Return ONLY valid JSON with these exact fields:
{
  "service": string (one of: AC Technician, Plumber, Electrician, Carpenter, Mechanic, Painter, or 'unknown'),
  "location": string (area name in Hyderabad, or 'not specified'),
  "timePreference": string (e.g. 'aaj', 'kal subah', 'urgent', 'tomorrow morning', or 'not specified'),
  "isUrgent": boolean (true if words like 'urgent', 'abhi', 'jaldi', 'emergency' are present),
  "confidence": number (0.0 to 1.0, how confident you are in this extraction),
  "detectedLanguage": string ('urdu', 'roman_urdu', 'english', 'mixed'),
  "clarificationNeeded": boolean (true if confidence < 0.75),
  "clarificationQuestion": string (in same language as input, ask ONE question to clarify — only if clarificationNeeded is true),
  "reasoning": string (explain your extraction logic)
}`;

        const result = await geminiModel.generateContent(prompt);
        const responseText = result.response.text();
        
        const jsonStr = responseText.replace(/```json/g, '').replace(/```/g, '').trim();
        const parsedData = JSON.parse(jsonStr);

        const log = `Agent 1 (Intent Extractor)\nInput: ${userInput}\nDetected Language: ${parsedData.detectedLanguage}\nConfidence: ${parsedData.confidence}\nExtracted: ${JSON.stringify(parsedData)}\nReasoning: ${parsedData.reasoning}`;

        return {
            success: true,
            data: parsedData,
            log: log
        };
    } catch (error: any) {
        console.error("Error in extractIntent:", error);
        return {
            success: false,
            error: error.message
        };
    }
});
