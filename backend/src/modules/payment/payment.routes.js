import { Router } from 'express';
import * as paymentController from './payment.controller.js';
import * as vnpayController from './vnpay.controller.js';
import { authenticateToken } from '../../middleware/authMiddleware.js';

const router = Router();

// Endpoint for app to request a payment URL
router.post('/momo/create', paymentController.createPaymentUrl);

// Webhook endpoint for MoMo to send payment results
router.post('/momo/callback', paymentController.ipnCallback);

// Mock endpoints for when real MoMo API is unavailable
router.get('/momo/mock-page', paymentController.renderMockMoMoPage);
router.post('/momo/mock-process', paymentController.processMockPayment);

// VNPay Endpoints
router.post('/vnpay/create', authenticateToken, vnpayController.createVNPayUrl);
router.get('/vnpay/callback', vnpayController.vnpayReturn);
router.get('/vnpay/ipn', vnpayController.vnpayIpn);

// Transaction History
router.get('/history', authenticateToken, vnpayController.getTransactionHistory);

export default router;
