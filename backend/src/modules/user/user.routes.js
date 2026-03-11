import { Router } from 'express';
import { requireAuth } from '../../db/middlewares/requireAuth.js';
import { getMe, updateMe } from './user.controller.js';

const router = Router();

router.get('/me', requireAuth, getMe);
router.put('/me', requireAuth, updateMe);

export default router;
