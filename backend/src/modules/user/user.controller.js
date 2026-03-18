import { updateProfileSchema, changePasswordSchema } from './user.validation.js';
import { getUserProfile, updateUserProfile, changeUserPassword, getAllUsersService, toggleUserStatusService } from './user.service.js';

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
