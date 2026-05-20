import { onCall } from 'firebase-functions/v2/https';
import { geminiModel } from '../config/gemini';

export const calculatePricing = onCall(async (request) => {
    try {
        const { provider, distanceKm, isUrgent } = request.data;
        if (!provider) {
            throw new Error("Missing provider object");
        }

        const baseFee = provider.baseRatePkr || 0;
        const pkrPerKm = provider.pkrPerKm || 0;
        const urgentSurcharge = provider.urgentSurcharge || 0;

        const prompt = `You are a pricing agent for HireIn Pakistan. Calculate the exact visit fee for this service booking.
  
Provider base rate: ${baseFee} PKR
Distance: ${distanceKm} km
PKR per km rate: ${pkrPerKm}
Is Urgent: ${isUrgent}
Urgent surcharge: ${urgentSurcharge} PKR
Platform fee rate: 10%

Calculate:
1. Travel Fee = distanceKm * pkrPerKm
2. Subtotal = baseFee + travelFee + (urgentSurcharge if urgent)
3. Platform Fee = subtotal * 0.10
4. Total = subtotal + platformFee

Return ONLY valid JSON:
{
  "baseFee": number,
  "travelFee": number,
  "urgentSurcharge": number,
  "subtotal": number,
  "platformFee": number,
  "total": number,
  "breakdown": "string (human-readable itemized breakdown in PKR)",
  "reasoning": "string"
}`;

        const result = await geminiModel.generateContent(prompt);
        const responseText = result.response.text();
        
        const jsonStr = responseText.replace(/```json/g, '').replace(/```/g, '').trim();
        const parsedData = JSON.parse(jsonStr);

        const log = `Agent 4 (Pricing Engine)\nProvider: ${provider.id}\nTotal: ${parsedData.total} PKR\nBreakdown: ${parsedData.breakdown}`;

        return {
            success: true,
            data: parsedData,
            log: log
        };
    } catch (error: any) {
        console.error("Error in calculatePricing:", error);
        return {
            success: false,
            error: error.message
        };
    }
});
