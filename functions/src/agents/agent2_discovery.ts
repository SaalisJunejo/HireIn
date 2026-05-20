import { onCall } from 'firebase-functions/v2/https';
import { db } from '../config/firebase';
import * as geofire from 'geofire-common';

export const discoverProviders = onCall(async (request) => {
    try {
        const { service, customerLat, customerLng } = request.data;
        if (!service || customerLat === undefined || customerLng === undefined) {
            throw new Error("Missing required fields");
        }

        let radiusInM = 15000; // 15km
        let providersData: any[] = [];

        const providersRef = db.collection('providers');
        const query = providersRef.where('category', '==', service).where('approvalStatus', '==', 'approved');
        const snapshot = await query.get();

        snapshot.forEach(doc => {
            const data = doc.data();
            if (data.lat !== undefined && data.lng !== undefined) {
                const distanceInKm = geofire.distanceBetween([customerLat, customerLng], [data.lat, data.lng]);
                data.distanceKm = distanceInKm;
                providersData.push(data);
            }
        });

        // Filter by radius 15km
        let filteredProviders = providersData.filter(p => p.distanceKm <= 15);
        
        // Expand radius to 25km if less than 3 providers
        if (filteredProviders.length < 3) {
            radiusInM = 25000;
            filteredProviders = providersData.filter(p => p.distanceKm <= 25);
        }

        const log = `Agent 2 (Discovery)\nSearched: ${service}\nRadius: ${radiusInM/1000}km\nFound: ${filteredProviders.length} providers`;

        return {
            success: true,
            data: filteredProviders,
            log: log
        };
    } catch (error: any) {
        console.error("Error in discoverProviders:", error);
        return {
            success: false,
            error: error.message
        };
    }
});
