import { Router } from 'express';
import { requireAuth } from '../../db/middlewares/requireAuth.js';
import { requireMarketingAdmin } from '../../db/middlewares/requireMarketingAdmin.js';
import {
  getStatsHandler,
  listPromotionsHandler,
  listAvailablePromotionsHandler,
  createPromotionHandler,
  updatePromotionHandler,
  deletePromotionHandler,
  getSegmentsHandler
} from './promotions.controller.js';

const router = Router();

router.get('/available', requireAuth, listAvailablePromotionsHandler);

router.use(requireAuth);
router.use(requireMarketingAdmin);

router.get('/stats', getStatsHandler);
router.get('/segments', getSegmentsHandler);
router.get('/', listPromotionsHandler);
router.post('/', createPromotionHandler);
router.put('/:id', updatePromotionHandler);
router.delete('/:id', deletePromotionHandler);

export default router;
