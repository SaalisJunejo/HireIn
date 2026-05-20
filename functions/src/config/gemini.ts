import { GoogleGenerativeAI } from '@google/generative-ai';

let cachedModel: any = null;

export const geminiModel = {
    generateContent: async (prompt: string) => {
        if (!cachedModel) {
            const apiKey = process.env.GEMINI_API_KEY || '';
            if (!apiKey) {
                throw new Error("GEMINI_API_KEY is missing from environment variables.");
            }
            const genAI = new GoogleGenerativeAI(apiKey);
            cachedModel = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });
        }
        return cachedModel.generateContent(prompt);
    }
};
