import express from 'express';
import * as appealController from './appeal.controller.js';
import { authenticateToken } from '../../middleware/authMiddleware.js';
import { isAdmin } from '../../middleware/adminMiddleware.js';

const router = express.Router();

/**
 * Public/User Routes
 * Chú ý: authenticateToken sẽ verify user ngay cả khi bị BLOCKED (chúng ta sẽ điều chỉnh middleware nếu cần)
 */
// Gửi đơn kháng cáo
router.post('/', authenticateToken, appealController.submitAppeal);
// Xem trạng thái kháng cáo mới nhất của tôi
router.get('/my-latest', authenticateToken, appealController.getMyLatestAppeal);

/**
 * Admin Routes
 */
// Lấy danh sách các đơn kháng cáo (theo trạng thái PENDING, APPROVED, REJECTED)
router.get('/admin/list', authenticateToken, isAdmin, appealController.listAppeals);
// Phản hồi (chấp nhận/từ chối) đơn kháng cáo
router.put('/admin/:id/respond', authenticateToken, isAdmin, appealController.respondToAppeal);

export default router;
