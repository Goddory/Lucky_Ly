import { createDepositLink, handlePayOSWebhook, getTransactionStatus } from './payment.service.js';

// POST /api/payment/create-payment-link
export async function createPaymentLink(req, res, next) {
  try {
    const userId = req.user.userId;
    const { amount, description } = req.body;
    console.log('[DEBUG] createPaymentLink:', { userId, amount, description });

    const data = await createDepositLink(userId, Number(amount), description);
    console.log('[DEBUG] createPaymentLink Success:', data);
    return res.status(200).json({ success: true, data });
  } catch (err) {
    console.error('[ERROR] createPaymentLink:', err);
    next(err);
  }
}

// POST /api/payment/payos-webhook
export async function payosWebhook(req, res, next) {
  try {
    const result = await handlePayOSWebhook(req.body);
    return res.status(200).json(result);
  } catch (err) {
    // PayOS luôn cần nhận HTTP 200 kể cả lỗi nội bộ
    console.error('[PayOS Webhook Error]', err.message);
    return res.status(200).json({ received: true });
  }
}

// GET /api/payment/check-status/:orderCode
export async function checkTransactionStatus(req, res, next) {
  try {
    const { orderCode } = req.params;
    const status = await getTransactionStatus(orderCode);
    
    if (!status) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy giao dịch' });
    }
    
    return res.status(200).json({ success: true, data: status });
  } catch (err) {
    next(err);
  }
}

// GET /api/payment/success
export async function paymentSuccess(req, res) {
  return res.status(200).json({ message: 'Thanh toán thành công, ví đang được cập nhật.' });
}

// GET /api/payment/cancel
export async function paymentCancel(req, res) {
  return res.status(200).json({ message: 'Giao dịch đã bị hủy.' });
}

