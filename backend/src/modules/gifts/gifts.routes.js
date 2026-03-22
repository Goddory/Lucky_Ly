import express from 'express';
import * as giftsController from './gifts.controller.js';
import { authenticateToken } from '../../middleware/authMiddleware.js';

const router = express.Router();

router.use(authenticateToken);

router.post('/', giftsController.sendGift);
router.get('/received', giftsController.listReceivedGifts);
router.get('/sent', giftsController.listSentGifts);
router.get('/pending-count', giftsController.getPendingCount);
router.get('/:id', giftsController.getGiftDetail);
router.patch('/:id/open', giftsController.openGift);

export default router;
