import { Router } from 'express';
import * as paymentController from './payment.controller.js';
import * as vnpayController from './vnpay.controller.js';
import * as zalopayController from './zalopay.controller.js';
import * as walletController from './wallet.controller.js';
import { authenticateToken } from '../../middleware/authMiddleware.js';
import { requireAdmin } from '../../db/middlewares/requireAdmin.js';

const router = Router();

// Endpoint for app to request a payment URL
router.post('/momo/create', authenticateToken, paymentController.createPaymentUrl);

// Webhook endpoint for MoMo to send payment results
router.post('/momo/callback', paymentController.ipnCallback);

// Redirect endpoint for users returning from MoMo
router.get('/momo/redirect', paymentController.momoRedirect);

// Mock endpoints — only available in non-production environments
if (process.env.NODE_ENV !== 'production') {
  router.get('/momo/mock-page', paymentController.renderMockMoMoPage);
  router.post('/momo/mock-process', paymentController.processMockPayment);
}

// VNPay Endpoints
router.post('/vnpay/create', authenticateToken, vnpayController.createVNPayUrl);
router.get('/vnpay/callback', vnpayController.vnpayReturn);
router.get('/vnpay/ipn', vnpayController.vnpayIpn);

// ZaloPay Endpoints
router.post('/zalopay/create', authenticateToken, zalopayController.createZaloPayUrl);
router.post('/zalopay/callback', zalopayController.zaloPayCallback);
router.get('/zalopay/return', zalopayController.zaloPayReturn);
router.post('/zalopay/query', authenticateToken, zalopayController.checkZaloPayStatus);

// Transaction History
router.get('/history', authenticateToken, vnpayController.getTransactionHistory);

// Wallet Operations
router.get('/wallet/balance', authenticateToken, walletController.getBalance);
router.post('/wallet/withdraw', authenticateToken, walletController.withdraw);
router.post('/wallet/transfer', authenticateToken, walletController.transfer);
router.post('/wallet/admin-add', authenticateToken, requireAdmin, walletController.adminAddMoney);

export default router;
