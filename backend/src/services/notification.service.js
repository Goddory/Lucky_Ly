import admin from 'firebase-admin';
import { readFileSync } from 'fs';
import { emitToUser } from '../sockets/chat.socket.js';
import { pool } from '../db/pool.js';

let firebaseInitialized = false;

export function initFirebase() {
  if (firebaseInitialized) return;

  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (!serviceAccountPath) {
    console.warn('⚠️ FIREBASE_SERVICE_ACCOUNT_PATH not set. Push notifications disabled.');
    return;
  }

  try {
    const serviceAccount = JSON.parse(readFileSync(serviceAccountPath, 'utf-8'));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    firebaseInitialized = true;
    console.log('✅ Firebase Admin SDK initialized');
  } catch (err) {
    console.error('⚠️ Firebase Admin init failed:', err.message);
  }
}

async function getUserFcmToken(userId) {
  const { rows } = await pool.query(
    `SELECT fcm_token FROM users WHERE user_id = $1 AND fcm_token IS NOT NULL LIMIT 1`,
    [userId]
  );
  return rows[0]?.fcm_token || null;
}

async function sendPushNotification(userId, title, body, data = {}) {
  emitToUser(userId, 'notification', { title, body, data, timestamp: new Date().toISOString() });

  if (!firebaseInitialized) return;

  const fcmToken = await getUserFcmToken(userId);
  if (!fcmToken) return;

  try {
    await admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      data: { ...data, click_action: 'FLUTTER_NOTIFICATION_CLICK' },
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default', badge: 1 } } }
    });
  } catch (err) {
    if (err.code === 'messaging/registration-token-not-registered') {
      await pool.query(`UPDATE users SET fcm_token = NULL WHERE user_id = $1`, [userId]);
    }
    console.error(`FCM send failed for user ${userId}:`, err.message);
  }
}

export async function notifyGiftReceived(receiverId, senderName, giftId) {
  await sendPushNotification(receiverId,
    '🎁 Bạn nhận được quà!',
    `${senderName} đã gửi cho bạn một món quà`,
    { type: 'gift_received', giftId: String(giftId) }
  );
}

export async function notifyGiftSent(senderId, receiverName, giftId) {
  await sendPushNotification(senderId,
    '🎁 Quà đã được gửi!',
    `Bạn đã tặng quà thành công cho ${receiverName}`,
    { type: 'gift_sent', giftId: String(giftId) }
  );
}

export async function notifyGiftClaimed(senderId, claimerName, giftId) {
  await sendPushNotification(senderId,
    '🎁 Quà đã được nhận!',
    `${claimerName} đã nhận món quà của bạn`,
    { type: 'gift_claimed', giftId: String(giftId) }
  );
}

export async function notifyFriendRequest(receiverId, senderName) {
  await sendPushNotification(receiverId,
    '👋 Lời mời kết bạn',
    `${senderName} muốn kết bạn với bạn`,
    { type: 'friend_request' }
  );
}

export async function notifyFriendAccepted(senderId, accepterName) {
  await sendPushNotification(senderId,
    '🤝 Kết bạn thành công!',
    `${accepterName} đã chấp nhận lời mời kết bạn`,
    { type: 'friend_accepted' }
  );
}

export async function notifyNewMessage(receiverId, senderName, content, roomId) {
  await sendPushNotification(receiverId,
    `💬 Tin nhắn từ ${senderName}`,
    content.length > 100 ? content.substring(0, 100) + '...' : content,
    { type: 'new_message', roomId: String(roomId) }
  );
}
