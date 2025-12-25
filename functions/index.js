/**
 * Cloud Functions: Kampüs Bildirim FCM Servisleri
 * 
 * 1. sendEmergencyNotification: Acil duyuruları tüm kullanıcılara gönderir
 * 2. sendStatusUpdateNotification: Takip edilen bildirimlerin durum değişikliklerini takipçilere gönderir
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Firestore referansı
const db = admin.firestore();

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

/**
 * status_updates collection'a yeni doküman eklendiğinde tetiklenir
 * Bildirim durumu değiştiğinde takipçilere push notification gönderir
 */
exports.sendStatusUpdateNotification = functions.firestore
  .document('status_updates/{docId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    
    const notificationId = data.notificationId;
    const notificationTitle = data.notificationTitle || 'Bildirim';
    const oldStatus = data.oldStatus || 'open';
    const newStatus = data.newStatus || 'open';
    const followers = data.followers || [];

    // Takipçi yoksa işlem yapma
    if (followers.length === 0) {
      console.log('⚠️ Takipçi yok, FCM gönderilmedi');
      await snap.ref.update({ sent: false, reason: 'no_followers' });
      return { success: false, reason: 'no_followers' };
    }

    // Durum etiketlerini Türkçeleştir
    const statusLabels = {
      'open': 'Açık',
      'reviewing': 'İnceleniyor',
      'resolved': 'Çözüldü'
    };

    const newStatusLabel = statusLabels[newStatus] || newStatus;

    // Her takipçi için FCM token'ını al ve bildirim gönder
    const sendPromises = followers.map(async (userId) => {
      try {
        // Kullanıcının FCM token'ını al
        const userDoc = await db.collection('users').doc(userId).get();
        
        if (!userDoc.exists) {
          console.log(`⚠️ Kullanıcı bulunamadı: ${userId}`);
          return { userId, success: false, reason: 'user_not_found' };
        }

        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;

        // Token yoksa topic bazlı gönder (kullanıcı 'all' topic'ine kayıtlı)
        // Bu durumda bireysel bildirim gönderemeyiz, sadece log tutalım
        if (!fcmToken) {
          console.log(`⚠️ FCM token yok: ${userId}`);
          return { userId, success: false, reason: 'no_fcm_token' };
        }

        // FCM mesajı oluştur
        const message = {
          notification: {
            title: '📢 Durum Güncellendi',
            body: `"${notificationTitle}" bildirimi artık "${newStatusLabel}" durumunda.`,
          },
          data: {
            type: 'status_update',
            notificationId: notificationId,
            oldStatus: oldStatus,
            newStatus: newStatus,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
          android: {
            notification: {
              icon: 'ic_notification',
              color: '#2196F3',
              channelId: 'status_channel',
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
              },
            },
          },
          token: fcmToken,
        };

        const response = await admin.messaging().send(message);
        console.log(`✅ FCM gönderildi: ${userId}`, response);
        return { userId, success: true, messageId: response };

      } catch (error) {
        console.error(`❌ FCM hatası (${userId}):`, error.message);
        return { userId, success: false, error: error.message };
      }
    });

    try {
      const results = await Promise.all(sendPromises);
      const successCount = results.filter(r => r.success).length;
      
      console.log(`📊 Durum bildirimi sonucu: ${successCount}/${followers.length} başarılı`);
      
      await snap.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        results: results,
        successCount: successCount,
        totalFollowers: followers.length,
      });

      return { success: true, successCount, totalFollowers: followers.length };
    } catch (error) {
      console.error('❌ Toplu gönderim hatası:', error);
      await snap.ref.update({ sent: false, error: error.message });
      return { success: false, error: error.message };
    }
  });
