import { Router } from 'express';
import { requireAuth } from '../../db/middlewares/requireAuth.js';
import { requireAdmin } from '../../db/middlewares/requireAdmin.js';
import { getTheme, updateTheme } from './theme.controller.js';

const router = Router();

router.get('/', requireAuth, getTheme);
router.put('/', requireAuth, requireAdmin, updateTheme);

export default router;