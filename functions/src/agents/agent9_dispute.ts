import { onCall } from 'firebase-functions/v2/https';
import { geminiModel } from '../config/gemini';
import { db } from '../config/firebase';

export const handleDispute = onCall(async (request) => {
    try {
        const { bookingId, customerId, providerId, disputeType, description } = request.data;
        if (!bookingId || !disputeType || !description) {
            throw new Error("Missing required fields for dispute");
        }

        const bookingRef = db.collection('bookings').doc(bookingId);
        const bookingSnap = await bookingRef.get();
        const bookingData = bookingSnap.data() || {};

        const providerRef = db.collection('providers').doc(providerId);
        const providerSnap = await providerRef.get();
        const providerData = providerSnap.data() || {};

        const prompt = `You are a dispute resolution agent for HireIn Pakistan.
  
Dispute type: ${disputeType} (no_show / overcharge / poor_quality / provider_cancelled / other)
Customer description: ${description}
Booking details: ${JSON.stringify(bookingData)}
Provider history: rating ${providerData.rating}, riskScore ${providerData.riskScore}, cancellationRate ${providerData.cancellationRate}

Resolve this dispute automatically if possible. For each type:
- no_show: full refund, provider risk score +0.3, flag for admin review
- overcharge: compare claimed amount vs receipt, if >10% difference: partial refund + provider warning
- provider_cancelled: notify customer, find next ranked provider (return nextProviderId), ask customer to confirm rebooking
- poor_quality: if rating < 2: 30% refund + provider flag
- other: escalate to admin

Return ONLY valid JSON:
{
  "resolution": "string (auto_resolved / escalated / pending_customer_confirmation)",
  "action": "string (refund_full / refund_partial / rebooking_suggested / warning_issued / escalated)",
  "refundAmount": number,
  "providerPenalty": "string",
  "riskScoreChange": number,
  "messageToCustomer": "string (in simple English)",
  "messageToProvider": "string",
  "nextProviderId": "string or null",
  "requiresCustomerConfirmation": boolean,
  "reasoning": "string",
  "log": "string"
}`;

        const apiKey = process.env.GEMINI_API_KEY || '';
        let responseText = '';
        
        if (!apiKey) {
            console.warn("GEMINI_API_KEY is missing. Running Agent 9 in Fallback Algorithmic Mode.");
            const mockParsedData = {
                resolution: "auto_resolved",
                action: "refund_full",
                refundAmount: 0,
                providerPenalty: "warning",
                riskScoreChange: 0,
                messageToCustomer: "Your dispute has been received and resolved.",
                messageToProvider: "A dispute was filed against you.",
                nextProviderId: null,
                requiresCustomerConfirmation: false,
                reasoning: "Fallback mock executed for dispute.",
                log: "Fallback executed."
            };
            responseText = JSON.stringify(mockParsedData);
        } else {
            const result = await geminiModel.generateContent(prompt);
            responseText = result.response.text();
        }
        
        const jsonStr = responseText.replace(/```json/g, '').replace(/```/g, '').trim();
        const parsedData = JSON.parse(jsonStr);

        const log = `Agent 9 (Dispute)\nResolution: ${parsedData.resolution}\nAction: ${parsedData.action}\nLog: ${parsedData.log}`;

        // Save dispute record
        await db.collection('disputes').add({
            bookingId,
            customerId,
            providerId,
            disputeType,
            description,
            resolution: parsedData.resolution,
            action: parsedData.action,
            refundAmount: parsedData.refundAmount,
            createdAt: new Date().toISOString()
        });

        // Update provider risk score
        if (parsedData.riskScoreChange) {
            await providerRef.update({
                riskScore: (providerData.riskScore || 0) + parsedData.riskScoreChange
            });
        }

        return {
            success: true,
            isFallback: !apiKey,
            data: parsedData,
            log: log
        };
    } catch (error: any) {
        console.error("Error in handleDispute:", error);
        return {
            success: false,
            error: error.message
        };
    }
});
