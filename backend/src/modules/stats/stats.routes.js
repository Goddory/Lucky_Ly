import { Router } from 'express';
import { requireAuth } from '../../db/middlewares/requireAuth.js';
import { overview, chart } from './stats.controller.js';

const router = Router();

router.get('/overview', requireAuth, overview);
router.get('/chart', requireAuth, chart);

export default router;
