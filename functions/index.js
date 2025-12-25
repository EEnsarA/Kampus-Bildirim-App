/**
 * Cloud Function: Acil Durum Bildirimlerini FCM ile Gönder
 * 
 * Firestore'da `fcm_messages` collection'ına yeni doküman eklendiğinde
 * tetiklenir ve 'all' topic'ine abone tüm cihazlara push notification gönderir.
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * fcm_messages collection'a yeni doküman eklendiğinde tetiklenir
 * Admin panelinden acil duyuru gönderildiğinde bu function çalışır
 */
exports.sendEmergencyNotification = functions.firestore
  .document('fcm_messages/{docId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    
    // Bildirim içeriğini al
    const title = data.title || '🚨 Acil Duyuru';
    const body = data.content || 'Kampüste acil durum bildirimi!';
    const notificationId = data.notificationId || '';

    // FCM mesajı oluştur
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        // Uygulama açıldığında yönlendirme için
        type: 'emergency',
        notificationId: notificationId,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      // Android için özel ayarlar
      android: {
        notification: {
          icon: 'ic_notification',
          color: '#FF0000',
          priority: 'high',
          channelId: 'emergency_channel',
        },
        priority: 'high',
      },
      // iOS için özel ayarlar
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
      // Web için özel ayarlar
      webpush: {
        notification: {
          icon: '/icons/Icon-192.png',
          badge: '/icons/Icon-192.png',
        },
      },
      // 'all' topic'ine gönder - tüm kullanıcılar bu topic'e subscribe
      topic: 'all',
    };

    try {
      const response = await admin.messaging().send(message);
      console.log('✅ FCM başarıyla gönderildi:', response);
      
      // Gönderim durumunu güncelle
      await snap.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        fcmResponse: response,
      });
      
      return { success: true, messageId: response };
    } catch (error) {
      console.error('❌ FCM gönderim hatası:', error);
      
      // Hata durumunu kaydet
      await snap.ref.update({
        sent: false,
        error: error.message,
      });
      
      return { success: false, error: error.message };
    }
  });
