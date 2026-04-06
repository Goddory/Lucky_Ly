import express from 'express';
import * as giftsController from './gifts.controller.js';
import { authenticateToken } from '../../middleware/authMiddleware.js';

const router = express.Router();

router.use(authenticateToken);

// Named routes first (before /:id wildcard)
router.post('/', giftsController.sendGift);
router.post('/link', giftsController.createGiftLink);
router.post('/claim/:token', giftsController.claimGift);
router.get('/received', giftsController.listReceivedGifts);
router.get('/sent', giftsController.listSentGifts);
router.get('/pending-count', giftsController.getPendingCount);
router.get('/refunds', giftsController.listRefundedGiftsMonitor);
router.get('/preview/:token', giftsController.previewGiftByToken);

// Parameterized routes last
router.get('/:id', giftsController.getGiftDetail);
router.patch('/:id/open', giftsController.openGift);
router.patch('/:id/receive', giftsController.receiveGiftCash);
router.patch('/:id/cancel', giftsController.cancelGift);

export default router;
