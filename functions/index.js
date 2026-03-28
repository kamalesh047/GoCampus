const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

/**
 * Haversine formula to calculate the distance between two points in kilometers.
 */
function getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
    const R = 6371; // Earth's radius in kilometers
    const dLat = (lat2 - lat1) * (Math.PI / 180);
    const dLon = (lon2 - lon1) * (Math.PI / 180);
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c; // Distance in km
}

/**
 * Monitors the buses collection for location updates.
 * If ETA to a student's assigned stop is <= 10 minutes, dispatches an FCM message.
 */
exports.checkBusETAAndNotify = functions.firestore
    .document('buses/{busId}')
    .onUpdate(async (change, context) => {
        const busId = context.params.busId;
        const busDataAfter = change.after.data();

        // 1. Extract coordinates dynamically handling GeoPoint or scalar values
        let currentLat, currentLng;
        if (busDataAfter.currentLocation) {
            currentLat = busDataAfter.currentLocation.latitude;
            currentLng = busDataAfter.currentLocation.longitude;
        } else if (busDataAfter.latitude && busDataAfter.longitude) {
            currentLat = busDataAfter.latitude;
            currentLng = busDataAfter.longitude;
        } else {
            console.log(`Bus ${busId} has no location data. Aborting.`);
            return null;
        }

        // Apply average speed fallback if sensors report 0
        let speedKmh = busDataAfter.speed || null;
        if (!speedKmh || speedKmh <= 0) {
            speedKmh = 15; // Set 15km/h as rough campus minimum cruising speed
        }

        try {
            // 2. Query all students assigned to this bus who haven't been notified yet
            const usersSnapshot = await db.collection('users')
                .where('role', '==', 'student')
                .where('busId', '==', busId)
                .where('notificationsSent', '!=', true)
                .get();

            if (usersSnapshot.empty) {
                console.log(`No eligible unnotified students found for bus ${busId}.`);
                return null;
            }

            const operations = [];

            // 3. Process each eligible student
            for (const studentDoc of usersSnapshot.docs) {
                const studentData = studentDoc.data();
                const stopId = studentData.stopId;
                const fcmToken = studentData.fcmToken; 
                
                if (!stopId) continue;

                // 4. Load static coordinates of the student's assigned stop
                const stopSnapshot = await db.collection('stops').doc(stopId).get();
                if (!stopSnapshot.exists) continue;

                const stopData = stopSnapshot.data();
                const stopLat = stopData.latitude;
                const stopLng = stopData.longitude;

                if (!stopLat || !stopLng) continue;

                // 5. Compute Euclidean distance mapping to ETA constraint
                const distanceKm = getDistanceFromLatLonInKm(currentLat, currentLng, stopLat, stopLng);
                const etaHours = distanceKm / speedKmh;
                const etaMinutes = Math.ceil(etaHours * 60);

                // 6. Trigger matrix: If 10 minutes away
                if (etaMinutes <= 10 && etaMinutes > 0) {
                    
                    // Mark global flag preventing duplicate triggers
                    operations.push(studentDoc.ref.update({
                        notificationsSent: true
                    }));

                    const notificationPayload = {
                        notification: {
                            title: 'Bus Arriving Soon',
                            body: 'Your bus will reach your stop in 10 minutes'
                        }
                    };

                    // Execute cloud message dispatch directly to device
                    if (fcmToken) {
                        notificationPayload.token = fcmToken;
                        const notifyPromise = admin.messaging().send(notificationPayload)
                            .then(res => console.log(`FCM Sent to ${studentDoc.id}:`, res))
                            .catch(err => console.error(`FCM Failed for ${studentDoc.id}:`, err));
                        operations.push(notifyPromise);
                    } else {
                        // Fallback logic for Topic-based registration 
                        notificationPayload.topic = `student_${studentDoc.id}`;
                        const notifyTopicPromise = admin.messaging().send(notificationPayload)
                            .catch(e => console.error(`Topic Notification failed for ${studentDoc.id}:`, e));
                        operations.push(notifyTopicPromise);
                    }

                    // Native Application log append (Simulates existing NotificationService structure)
                    operations.push(db.collection('notifications').add({
                        title: 'Bus Arriving Soon',
                        body: 'Your bus will reach your stop in 10 minutes',
                        targetRole: 'student',
                        targetUserId: studentDoc.id,
                        targetBusId: busId,
                        timestamp: admin.firestore.FieldValue.serverTimestamp()
                    }));
                }
            }

            // Sync all async mutations cleanly to avoid dangling process exits
            await Promise.all(operations);
            return null;

        } catch (error) {
            console.error('Critical ETA Calculation Hook Error:', error);
            return null;
        }
    });

/**
 * Cleanup routine triggered automatically when a new trip explicitly begins.
 * Resets all 'notificationsSent' global limiters back to false.
 */
exports.resetNotificationsOnTripStart = functions.firestore
    .document('trips/{tripId}')
    .onCreate(async (snap, context) => {
        const tripData = snap.data();
        const busId = tripData.busId;

        if (!busId) return null;

        try {
            // Find all students locked by previous dispatch loops
            const usersSnapshot = await db.collection('users')
                .where('role', '==', 'student')
                .where('busId', '==', busId)
                .where('notificationsSent', '==', true)
                .get();

            const batch = db.batch();
            usersSnapshot.docs.forEach((doc) => {
                batch.update(doc.ref, { notificationsSent: false });
            });

            console.log(`Reset ${usersSnapshot.size} notification locks globally for bus ${busId}.`);
            return batch.commit();

        } catch (error) {
            console.error('Failed to purge notification locks on Trip Generation Hook:', error);
            return null;
        }
    });
