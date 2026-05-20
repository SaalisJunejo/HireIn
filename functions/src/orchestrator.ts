import { onCall } from 'firebase-functions/v2/https';
import { extractIntent } from './agents/agent1_intent';
import { discoverProviders } from './agents/agent2_discovery';
import { rankProviders } from './agents/agent3_ranking';
import { calculatePricing } from './agents/agent4_pricing';
import { selectMatch } from './agents/agent5_matchmaker';

export const orchestrateAgents = onCall({ cors: true }, async (request) => {
    try {
        const { userInput, userId, customerLat, customerLng } = request.data;
        if (!userInput || !userId || customerLat === undefined || customerLng === undefined) {
            throw new Error("Missing required fields for orchestration");
        }

        const apiKey = process.env.GEMINI_API_KEY || '';
        if (!apiKey) {
            console.warn("GEMINI_API_KEY is missing. Running in Fallback Algorithmic Mode.");
            return {
                success: true,
                isFallback: true,
                data: {
                    category: 'AC Technician',
                    area: 'Qasimabad',
                    reasoningSummary: 'Yeh ek algorithmic fallback response hai kyunke Gemini API key missing hai. Ustad Ali ko as a fallback match chuna gaya hai.',
                    rankedProviders: [
                        {
                            id: 'PROV-FALLBACK',
                            name: 'Ustad Ali (Fallback)',
                            phone: '+923001234567',
                            category: 'AC Technician',
                            lat: customerLat + 0.001,
                            lng: customerLng + 0.001,
                            baseRatePkr: 200,
                            rating: 4.8,
                            approvalStatus: 'approved',
                            fcmToken: 'mock_token',
                            joinedAt: new Date().toISOString(),
                            skillLevel: 'expert',
                            completedJobs: 30,
                            areaName: 'Qasimabad',
                            cnicImagePath: ''
                        }
                    ]
                },
                logs: [
                    "⚠️ FALLBACK MODE ACTIVATED: Missing GEMINI_API_KEY.",
                    "Agent 1 (Intent) -> Skipped (Fallback: AC Technician, Qasimabad)",
                    "Agent 2 (Discovery) -> Skipped",
                    "Agent 3 (Ranking) -> Skipped",
                    "Agent 4 (Pricing) -> Skipped",
                    "Agent 5 (Matchmaker) -> Fallback selection provided."
                ]
            };
        }

        const logs: string[] = [];

        // 1. Agent 1: Intent Extractor
        const intentResult = await extractIntent.run({ data: { userInput, userId }, auth: request.auth } as any);
        if (!intentResult.success) throw new Error(intentResult.error);
        logs.push(intentResult.log || '');

        const { service, isUrgent } = intentResult.data;

        // 2. Agent 2: Discovery
        const discoveryResult = await discoverProviders.run({ data: { service, customerLat, customerLng, isUrgent }, auth: request.auth } as any);
        if (!discoveryResult.success) throw new Error(discoveryResult.error);
        logs.push(discoveryResult.log || '');
        
        const discoveredProviders = discoveryResult.data || [];
        if (discoveredProviders.length === 0) {
            return { success: false, message: "No providers found for this service.", logs };
        }

        // 3. Agent 3: Ranking
        const rankingResult = await rankProviders.run({ data: { providers: discoveredProviders, isUrgent }, auth: request.auth } as any);
        if (!rankingResult.success) throw new Error(rankingResult.error);
        logs.push(rankingResult.log || '');

        const rankedProviders = rankingResult.data.rankedProviders || [];

        // 4. Agent 4: Pricing Engine (Run for top 3 ranked providers)
        const topProviders = rankedProviders.slice(0, 3);
        const pricingResults = [];
        
        for (const provider of topProviders) {
            const pricingResult = await calculatePricing.run({ data: { provider, distanceKm: provider.distanceKm, isUrgent }, auth: request.auth } as any);
            if (pricingResult.success) {
                pricingResults.push({ providerId: provider.id, pricing: pricingResult.data });
                logs.push(pricingResult.log || '');
            }
        }

        // 5. Agent 5: Matchmaker
        const matchmakerResult = await selectMatch.run({ data: { rankedProviders: topProviders, pricingResults }, auth: request.auth } as any);
        if (!matchmakerResult.success) throw new Error(matchmakerResult.error);
        logs.push(matchmakerResult.log || '');

        return {
            success: true,
            isFallback: false,
            data: matchmakerResult.data,
            logs
        };

    } catch (error: any) {
        console.error("Error in orchestrateAgents:", error);
        return {
            success: false,
            error: error.message
        };
    }
});
