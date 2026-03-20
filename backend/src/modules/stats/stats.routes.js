import { Router } from 'express';
import { requireAuth } from '../../db/middlewares/requireAuth.js';
import { requireAdmin } from '../../db/middlewares/requireAdmin.js';
import { overview, chart } from './stats.controller.js';

const router = Router();

router.get('/overview', requireAuth, requireAdmin, overview);
router.get('/chart', requireAuth, requireAdmin, chart);

export default router;
