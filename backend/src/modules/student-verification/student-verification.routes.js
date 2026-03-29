import { Router } from 'express';
import { requireAuth } from '../../db/middlewares/requireAuth.js';
import { requireMarketingAdmin } from '../../db/middlewares/requireMarketingAdmin.js';
import {
  listVerificationsHandler,
  submitVerificationHandler,
  reviewVerificationHandler
} from './student-verification.controller.js';

const router = Router();

// User-facing: submit student card (only needs auth)
router.post('/', requireAuth, submitVerificationHandler);

// Admin-facing: list and review
router.get('/', requireAuth, requireMarketingAdmin, listVerificationsHandler);
router.put('/:id/review', requireAuth, requireMarketingAdmin, reviewVerificationHandler);

export default router;
