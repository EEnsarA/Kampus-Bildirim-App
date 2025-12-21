/**
 * Example Cloud Function that triggers on new documents in `fcm_messages`
 * and sends an FCM notification to all devices using a topic (e.g., 'all').
 *
 * This is a minimal example; deploy under `functions/` using Firebase CLI.
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendFcmOnMarker = functions.firestore
  .document('fcm_messages/{docId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const title = data.title || 'Acil Duyuru';
    const body = data.content || '';

    const message = {
      notification: {
        title: title,
        body: body,
      },
      topic: 'all',
    };

    try {
      const response = await admin.messaging().send(message);
      console.log('FCM sent:', response);
      return null;
    } catch (err) {
      console.error('FCM send error:', err);
      return null;
    }
  });
