import { updateProfileSchema } from './user.validation.js';
import { getUserProfile, updateUserProfile } from './user.service.js';

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
