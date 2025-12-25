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
    
    // Bildirim türünü al
    const messageType = data.type || 'emergency';
    
    // Bildirim içeriğini al
    const title = data.title || '🚨 Acil Duyuru';
    const body = data.content || 'Kampüste acil durum bildirimi!';
    const notificationId = data.notificationId || '';

    // Türe göre renk ve kanal belirle
    const isStatusUpdate = messageType === 'status_update';
    const notificationColor = isStatusUpdate ? '#2196F3' : '#FF0000'; // Mavi: durum, Kırmızı: acil
    const channelId = isStatusUpdate ? 'status_update_channel' : 'emergency_channel';

    // FCM mesajı oluştur
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        // Uygulama açıldığında yönlendirme için
        type: messageType,
        notificationId: notificationId,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      // Android için özel ayarlar
      android: {
        notification: {
          icon: 'ic_notification',
          color: notificationColor,
          priority: 'high',
          channelId: channelId,
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

    console.log(`🔔 Status update tetiklendi - Bildirim: ${notificationId}, Takipçi sayısı: ${followers.length}`);

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

    // Önce topic bazlı bildirim gönder (tüm takipçiler 'all' topic'ine kayıtlı)
    // Bu her zaman çalışır
    const topicMessage = {
      notification: {
        title: '📢 Durum Güncellendi',
        body: `"${notificationTitle}" bildirimi artık "${newStatusLabel}" durumunda.`,
      },
      data: {
        type: 'status_update',
        notificationId: notificationId || '',
        oldStatus: oldStatus,
        newStatus: newStatus,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        notification: {
          icon: 'ic_notification',
          color: '#2196F3',
          channelId: 'status_channel',
          priority: 'high',
        },
        priority: 'high',
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
      // Takipçi user ID'lerinden topic oluştur
      // Her takipçi kendi topic'ine subscribe olmalı
      topic: 'all', // Şimdilik tüm kullanıcılara gönder
    };

    try {
      // Topic bazlı gönder
      const topicResponse = await admin.messaging().send(topicMessage);
      console.log('✅ Topic FCM gönderildi:', topicResponse);

      await snap.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        method: 'topic',
        fcmResponse: topicResponse,
        followersCount: followers.length,
      });

      return { success: true, method: 'topic', messageId: topicResponse };
    } catch (error) {
      console.error('❌ FCM gönderim hatası:', error);
      await snap.ref.update({ sent: false, error: error.message });
      return { success: false, error: error.message };
    }
  });
