import { Router } from 'express';
import { pushSyncData, pullSyncData } from '../controllers/sync.controller.js';
import { requireAuth } from '../db/middlewares/requireAuth.js';

const router = Router();

router.use(requireAuth);

router.post('/push/:type', pushSyncData);
router.get('/pull/all', pullSyncData);
router.get('/pull/:type', pullSyncData); // fallback or single type if needed

export default router;
