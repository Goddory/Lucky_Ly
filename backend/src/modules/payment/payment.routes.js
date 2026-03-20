import { Router } from 'express';
import { requireAuth } from '../../db/middlewares/requireAuth.js';
import {
  createPaymentLink,
  payosWebhook,
  paymentSuccess,
  paymentCancel,
  checkTransactionStatus,
} from './payment.controller.js';

const router = Router();

// Tạo link thanh toán PayOS (cần đăng nhập)
router.post('/create-payment-link', requireAuth, createPaymentLink);

// Kiểm tra trạng thái giao dịch
router.get('/check-status/:orderCode', requireAuth, checkTransactionStatus);

// Webhook nhận từ PayOS (không cần xác thực – PayOS tự verify checksum)
router.post('/payos-webhook', payosWebhook);

// Redirect URL sau khi thanh toán
router.get('/success', paymentSuccess);
router.get('/cancel', paymentCancel);

export default router;

