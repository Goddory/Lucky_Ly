import { updateProfileSchema, changePasswordSchema } from './user.validation.js';
import { getUserProfile, updateUserProfile, changeUserPassword, getAllUsersService, toggleUserStatusService, updatePrivacySettings, updateFcmToken } from './user.service.js';
import { pool } from '../../db/pool.js';

// GET /api/users/me — Lấy thông tin profile user hiện tại.
export async function getMe(req, res, next) {
  try {
    const user = await getUserProfile(req.user.userId);
    res.status(200).json({ user });
  } catch (err) {
    next(err);
  }
}

// PUT /api/users/me — Cập nhật thông tin profile user hiện tại.
export async function updateMe(req, res, next) {
  try {
    const payload = updateProfileSchema.parse(req.body);
    const user = await updateUserProfile(req.user.userId, payload);

    res.status(200).json({
      message: 'Profile updated',
      user
    });
  } catch (err) {
    next(err);
  }
}

// PUT /api/users/me/password — Đổi mật khẩu
export async function updatePassword(req, res, next) {
  try {
    const { currentPassword, newPassword } = changePasswordSchema.parse(req.body);
    await changeUserPassword(req.user.userId, currentPassword, newPassword);

    res.status(200).json({
      message: 'Password changed successfully. Please log in again on other devices if needed.'
    });
  } catch (err) {
    next(err);
  }
}

// Lấy danh sách tài khoản
export async function getAllUsers(req, res, next) {
  try {
    const users = await getAllUsersService();
    res.status(200).json({ users });
  } catch (err) {
    next(err);
  }
}

// Thay đổi trạng thái tài khoản
export async function toggleUserStatus(req, res, next) {
  try {
    const { id } = req.params;
    const { isActive } = req.body;
    const user = await toggleUserStatusService(id, isActive);
    res.status(200).json({ message: 'User status updated', user });
  } catch (err) {
    next(err);
  }
}

export async function updatePrivacy(req, res, next) {
  try {
    const { isSearchable } = req.body;
    if (typeof isSearchable !== 'boolean') {
      return res.status(400).json({ message: 'isSearchable (boolean) is required' });
    }
    const result = await updatePrivacySettings(req.user.userId, isSearchable);
    res.status(200).json({ message: 'Privacy settings updated', user: result });
  } catch (err) {
    next(err);
  }
}

export async function updateDeviceToken(req, res, next) {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken) {
      return res.status(400).json({ message: 'fcmToken is required' });
    }
    await updateFcmToken(req.user.userId, fcmToken);
    res.status(200).json({ message: 'FCM token updated' });
  } catch (err) {
    next(err);
  }
}

export const getMyNotifications = async (req, res, next) => {
  try {
    const { userId } = req.user;
    const result = await pool.query(
      'SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50',
      [userId]
    );

    const unreadCount = result.rows.filter(r => !r.is_read).length;

    res.json({
      unread_count: unreadCount,
      notifications: result.rows
    });
  } catch (err) {
    next(err);
  }
};

export const markNotificationsRead = async (req, res, next) => {
  try {
    const { userId } = req.user;
    await pool.query(
      'UPDATE notifications SET is_read = true WHERE user_id = $1 AND is_read = false',
      [userId]
    );
    res.json({ message: 'All notifications marked as read' });
  } catch (err) {
    next(err);
  }
};
