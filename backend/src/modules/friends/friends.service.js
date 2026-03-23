import { pool } from '../../db/pool.js';

export async function sendFriendRequest(userId, friendId) {
  if (userId === friendId) {
    const err = new Error('Cannot send friend request to yourself');
    err.statusCode = 400;
    throw err;
  }

  const existing = await pool.query(
    `SELECT id, status FROM friends
     WHERE (user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1) LIMIT 1`,
    [userId, friendId]
  );

  if (existing.rowCount > 0) {
    const row = existing.rows[0];
    if (row.status === 'accepted') {
      const err = new Error('Already friends');
      err.statusCode = 409;
      throw err;
    }
    const err = new Error('Friend request already exists');
    err.statusCode = 409;
    throw err;
  }

  const { rows } = await pool.query(
    `INSERT INTO friends (user_id, friend_id, status) VALUES ($1, $2, 'pending') RETURNING *`,
    [userId, friendId]
  );

  return rows[0];
}

export async function acceptFriendRequest(requestId, currentUserId) {
  const { rows } = await pool.query(
    `UPDATE friends SET status = 'accepted', updated_at = NOW()
     WHERE id = $1 AND friend_id = $2 AND status = 'pending' RETURNING *`,
    [requestId, currentUserId]
  );

  if (rows.length === 0) {
    const err = new Error('Friend request not found or already processed');
    err.statusCode = 404;
    throw err;
  }

  return rows[0];
}

export async function declineFriendRequest(requestId, currentUserId) {
  const { rows } = await pool.query(
    `UPDATE friends SET status = 'declined', updated_at = NOW()
     WHERE id = $1 AND friend_id = $2 AND status = 'pending' RETURNING *`,
    [requestId, currentUserId]
  );

  if (rows.length === 0) {
    const err = new Error('Friend request not found or already processed');
    err.statusCode = 404;
    throw err;
  }

  return rows[0];
}

export async function unfriend(userId, friendId) {
  const { rowCount } = await pool.query(
    `DELETE FROM friends
     WHERE ((user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1))
       AND status = 'accepted'`,
    [userId, friendId]
  );

  if (rowCount === 0) {
    const err = new Error('Friendship not found');
    err.statusCode = 404;
    throw err;
  }
}

export async function getFriendsList(userId) {
  const { rows } = await pool.query(
    `SELECT u.user_id, u.username, u.full_name, u.avatar_url, f.created_at AS friends_since
     FROM friends f
     JOIN users u ON (CASE WHEN f.user_id = $1 THEN f.friend_id ELSE f.user_id END) = u.user_id
     WHERE (f.user_id = $1 OR f.friend_id = $1) AND f.status = 'accepted'
     ORDER BY u.username`,
    [userId]
  );
  return rows;
}

export async function getSentRequests(userId) {
  const { rows } = await pool.query(
    `SELECT f.id AS request_id, u.user_id, u.username, u.full_name, u.avatar_url, f.created_at
     FROM friends f
     JOIN users u ON f.friend_id = u.user_id
     WHERE f.user_id = $1 AND f.status = 'pending'
     ORDER BY f.created_at DESC`,
    [userId]
  );
  return rows;
}

export async function getReceivedRequests(userId) {
  const { rows } = await pool.query(
    `SELECT f.id AS request_id, u.user_id, u.username, u.full_name, u.avatar_url, f.created_at
     FROM friends f
     JOIN users u ON f.user_id = u.user_id
     WHERE f.friend_id = $1 AND f.status = 'pending'
     ORDER BY f.created_at DESC`,
    [userId]
  );
  return rows;
}

export async function areFriends(userId, friendId) {
  const { rowCount } = await pool.query(
    `SELECT 1 FROM friends
     WHERE ((user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1))
       AND status = 'accepted'
     LIMIT 1`,
    [userId, friendId]
  );
  return rowCount > 0;
}

export async function searchUsers(query, currentUserId) {
  const { rows } = await pool.query(
    `SELECT user_id, username, full_name, avatar_url
     FROM users
     WHERE (is_searchable IS NULL OR is_searchable = TRUE)
       AND user_id != $1
       AND (LOWER(username) LIKE LOWER($2) OR LOWER(full_name) LIKE LOWER($2))
     ORDER BY username
     LIMIT 20`,
    [currentUserId, `%${query}%`]
  );
  return rows;
}
