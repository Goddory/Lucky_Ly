import { Router } from 'express';
import { requireAuth } from '../../db/middlewares/requireAuth.js';
import { getMe, updateMe, updatePassword, getAllUsers, toggleUserStatus } from './user.controller.js';

const router = Router();

// User profile endpoints
router.get('/me', requireAuth, getMe);
router.put('/me', requireAuth, updateMe);
router.put('/me/password', requireAuth, updatePassword);

// Admin endpoints (Using requireAuth for now)
router.get('/', requireAuth, getAllUsers);
router.put('/:id/status', requireAuth, toggleUserStatus);

export default router;
