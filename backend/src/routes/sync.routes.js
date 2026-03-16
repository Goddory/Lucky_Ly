import { Router } from 'express';
import { pushSyncData, pullSyncData } from '../controllers/sync.controller.js';
import { requireAuth } from '../db/middlewares/requireAuth.js';

const router = Router();

router.use(requireAuth);

router.post('/push', pushSyncData);
router.get('/pull', pullSyncData);

export default router;
