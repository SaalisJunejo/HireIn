import { onCall } from 'firebase-functions/v2/https';

export const sendFollowUp = onCall(async (request) => {
    try {
        const { bookingId, type } = request.data;
        if (!bookingId || !type) {
            throw new Error("Missing bookingId or type");
        }

        let mockMessage = "";
        let logMessage = "";

        switch (type) {
            case 'reminder':
                mockMessage = "Reminder sent to customer 1 hour before slot";
                logMessage = `SMS Mock: Reminder sent to customer 1 hour before slot`;
                break;
            case 'en_route':
                mockMessage = "Provider is on the way alert sent";
                logMessage = `SMS Mock: Provider is on the way alert sent`;
                break;
            case 'completion_prompt':
                mockMessage = "Please rate your service";
                logMessage = `Push Mock: Please rate your service`;
                break;
            default:
                throw new Error("Invalid follow-up type");
        }

        const log = `Agent 7 (Follow-up)\n${logMessage}`;

        return {
            success: true,
            mockMessage: mockMessage,
            log: log
        };
    } catch (error: any) {
        console.error("Error in sendFollowUp:", error);
        return {
            success: false,
            error: error.message
        };
    }
});
