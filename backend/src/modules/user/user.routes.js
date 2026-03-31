import { Router } from 'express';
import { requireAuth } from '../../db/middlewares/requireAuth.js';
import { requireAdmin } from '../../db/middlewares/requireAdmin.js';
import { getMe, updateMe, updatePassword, getAllUsers, toggleUserStatus, updatePrivacy, updateDeviceToken, getMyNotifications, markNotificationsRead } from './user.controller.js';

const router = Router();

// User profile endpoints
router.get('/me', requireAuth, getMe);
router.put('/me', requireAuth, updateMe);
router.put('/me/password', requireAuth, updatePassword);
router.put('/me/privacy', requireAuth, updatePrivacy);
router.put('/me/fcm-token', requireAuth, updateDeviceToken);
router.get('/me/notifications', requireAuth, getMyNotifications);
router.put('/me/notifications/read', requireAuth, markNotificationsRead);

// Admin endpoints
router.get('/', requireAuth, requireAdmin, getAllUsers);
router.put('/:id/status', requireAuth, requireAdmin, toggleUserStatus);

export default router;
