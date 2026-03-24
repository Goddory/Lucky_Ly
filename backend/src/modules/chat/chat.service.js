import { pool } from '../../db/pool.js';
import { areFriends } from '../friends/friends.service.js';

export async function getOrCreatePrivateRoom(userId1, userId2) {
  const existing = await pool.query(
    `SELECT cr.id FROM chat_rooms cr
     JOIN chat_room_participants p1 ON cr.id = p1.room_id AND p1.user_id = $1
     JOIN chat_room_participants p2 ON cr.id = p2.room_id AND p2.user_id = $2
     WHERE cr.room_type = 'private'
     LIMIT 1`,
    [userId1, userId2]
  );

  if (existing.rowCount > 0) return existing.rows[0].id;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const room = await client.query(
      `INSERT INTO chat_rooms (room_type) VALUES ('private') RETURNING id`
    );
    const roomId = room.rows[0].id;

    await client.query(
      `INSERT INTO chat_room_participants (room_id, user_id) VALUES ($1, $2), ($1, $3)`,
      [roomId, userId1, userId2]
    );
    await client.query('COMMIT');
    return roomId;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

export async function sendMessage(roomId, senderId, receiverId, content, messageType = 'text', giftId = null) {
  const isFriend = await areFriends(senderId, receiverId);

  if (!isFriend) {
    const msgCount = await pool.query(
      `SELECT COUNT(*) AS count FROM chat_messages WHERE room_id = $1 AND sender_id = $2`,
      [roomId, senderId]
    );

    const count = parseInt(msgCount.rows[0].count, 10);
    if (count >= 1) {
      const err = new Error('You can only send 1 message to non-friends. Please add them as a friend to continue chatting.');
      err.statusCode = 403;
      throw err;
    }

    if (messageType !== 'gift') {
      const err = new Error('You can only send a gift message to non-friends.');
      err.statusCode = 403;
      throw err;
    }
  }

  const { rows } = await pool.query(
    `INSERT INTO chat_messages (room_id, sender_id, content, message_type, gift_id)
     VALUES ($1, $2, $3, $4, $5) RETURNING *`,
    [roomId, senderId, content, messageType, giftId]
  );

  return rows[0];
}

export async function getMessages(roomId, userId, limit = 50, beforeId = null) {
  const isParticipant = await pool.query(
    `SELECT 1 FROM chat_room_participants WHERE room_id = $1 AND user_id = $2 LIMIT 1`,
    [roomId, userId]
  );
  if (isParticipant.rowCount === 0) {
    const err = new Error('Not a participant of this chat room');
    err.statusCode = 403;
    throw err;
  }

  let query = `
    SELECT m.*, u.username AS sender_name, u.avatar_url AS sender_avatar
    FROM chat_messages m
    JOIN users u ON m.sender_id = u.user_id
    WHERE m.room_id = $1`;
  const params = [roomId];

  if (beforeId) {
    query += ` AND m.id < $${params.length + 1}`;
    params.push(beforeId);
  }

  query += ` ORDER BY m.created_at DESC LIMIT $${params.length + 1}`;
  params.push(limit);

  const { rows } = await pool.query(query, params);
  return rows.reverse();
}

export async function markMessagesAsRead(roomId, userId) {
  await pool.query(
    `UPDATE chat_messages SET is_read = TRUE
     WHERE room_id = $1 AND sender_id != $2 AND is_read = FALSE`,
    [roomId, userId]
  );
}

export async function getUserRooms(userId) {
  const { rows } = await pool.query(
    `SELECT cr.id AS room_id, cr.room_type, cr.updated_at,
       (SELECT json_agg(json_build_object(
         'user_id', u.user_id, 'username', u.username,
         'full_name', u.full_name, 'avatar_url', u.avatar_url
       )) FROM chat_room_participants p
         JOIN users u ON p.user_id = u.user_id
         WHERE p.room_id = cr.id AND p.user_id != $1
       ) AS other_participants,
       (SELECT json_build_object('content', lm.content, 'message_type', lm.message_type, 'created_at', lm.created_at, 'sender_id', lm.sender_id)
         FROM chat_messages lm WHERE lm.room_id = cr.id ORDER BY lm.created_at DESC LIMIT 1
       ) AS last_message,
       (SELECT COUNT(*) FROM chat_messages cm
         WHERE cm.room_id = cr.id AND cm.sender_id != $1 AND cm.is_read = FALSE
       ) AS unread_count
     FROM chat_rooms cr
     JOIN chat_room_participants cp ON cr.id = cp.room_id
     WHERE cp.user_id = $1
     ORDER BY cr.updated_at DESC`,
    [userId]
  );
  return rows;
}
