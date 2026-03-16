import { Router } from 'express';
import { authenticateToken } from '../../middleware/authMiddleware.js';
import { isAdmin } from '../../middleware/adminMiddleware.js';
import * as adminController from './admin.controller.js';

const router = Router();

router.use(authenticateToken, isAdmin);

router.get('/stats', adminController.getStats);
router.post('/theme', adminController.updateTheme);

// User Management
router.get('/users', adminController.listUsers);
router.get('/users/:id', adminController.getUserDetails);
router.put('/users/:id/status', adminController.updateUserStatus);
router.post('/users/:id/balance', adminController.updateBalance);

export default router;
