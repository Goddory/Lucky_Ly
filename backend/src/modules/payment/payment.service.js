import { PayOS } from '@payos/node';
import { pool } from '../../db/pool.js';
import { env } from '../../config/env.js';

const payos = new PayOS(
  env.payos.clientId,
  env.payos.apiKey,
  env.payos.checksumKey
);

// Tạo payment link PayOS để nạp tiền vào ví Lucky Ly
export async function createDepositLink(userId, amount, description) {
  if (!amount || amount < 1000) {
    const error = new Error('Số tiền nạp phải từ 1.000đ trở lên');
    error.statusCode = 400;
    throw error;
  }

  const timePart = String(Date.now()).slice(-6);
  const randPart = Math.floor(Math.random() * 899 + 100).toString();
  const orderCode = Number(timePart + randPart);

  const finalDescription = description || `NAP ${amount} ${String(userId).slice(-6)}`;

  const paymentData = {
    orderCode: orderCode,
    amount: amount,
    description: finalDescription,
    returnUrl: `${env.payos.returnUrl || 'http://localhost:4000'}/api/payment/success`,
    cancelUrl: `${env.payos.returnUrl || 'http://localhost:4000'}/api/payment/cancel`,
  };

  const paymentLinkResponse = await payos.paymentRequests.create(paymentData);

  // DEBUG: Xem giá trị nạp tiền trước khi lưu DB
  console.log('[DEBUG-SQL] Inserting transaction:', {
    userId, orderCode, amount, provider: 'payos', status: 'pending'
  });

  // LƯU VÀO DB: Tạo bản ghi giao dịch ở trạng thái pending (sửa lại thành order_id)
  await pool.query(
    `INSERT INTO transactions (user_id, order_id, amount, type, provider, status)
     VALUES ($1, $2, $3, 'deposit', 'payos', 'pending')`,
    [userId, orderCode, amount]
  );



  return {
    checkoutUrl: paymentLinkResponse.checkoutUrl,
    qrCode: paymentLinkResponse.qrCode,
    orderCode: paymentLinkResponse.orderCode,
    amount: paymentLinkResponse.amount,
  };
}

// Hàm dùng chung để xử lý khi giao dịch thành công (dùng cho cả Webhook và Proactive Check)
async function processSuccessfulTransaction(transaction, amount) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Cập nhật trạng thái giao dịch
    await client.query(
      "UPDATE transactions SET status = 'completed', updated_at = NOW() WHERE id = $1",
      [transaction.id]
    );

    // 2. Cộng tiền vào ví của người dùng
    await client.query(
      "UPDATE wallets SET balance = balance + $1, updated_at = NOW() WHERE user_id = $2",
      [amount, transaction.user_id]
    );

    await client.query('COMMIT');
    console.log(`[Payment] Nạp tiền thành công cho user ${transaction.user_id}: +${amount}đ (Transaction ID: ${transaction.id})`);
    return true;
  } catch (dbErr) {
    await client.query('ROLLBACK');
    console.error('[Payment DB Error]', dbErr.message);
    throw dbErr;
  } finally {
    client.release();
  }
}

// Xử lý Webhook từ PayOS – cộng tiền thẳng vào ví khi thanh toán thành công
export async function handlePayOSWebhook(webhookBody) {
  try {
    const verifiedData = payos.webhooks.verify(webhookBody);

    // Chỉ xử lý khi code là '00' (Thành công)
    if (verifiedData.code !== '00') return { received: true };

    const { orderCode, amount } = verifiedData;

    // Tìm giao dịch trong DB
    const transResult = await pool.query(
      'SELECT id, user_id, status FROM transactions WHERE order_id = $1 LIMIT 1',
      [orderCode]
    );

    if (transResult.rowCount === 0) {
      console.warn(`[PayOS Webhook] Không tìm thấy giao dịch với order_id: ${orderCode}`);
      return { received: true };
    }

    const transaction = transResult.rows[0];

    // Nếu giao dịch đã hoàn thành trước đó thì không làm gì thêm
    if (transaction.status === 'completed') {
      return { received: true };
    }

    await processSuccessfulTransaction(transaction, amount);

    return { received: true };
  } catch (err) {
    console.error('[PayOS Webhook Error]', err.message);
    // Vẫn trả về received: true để PayOS không gửi đi gửi lại nếu là lỗi logic bên mình
    return { received: true };
  }
}

// Kiểm tra trạng thái giao dịch cho Mobile Polling - có chủ động check với PayOS
export async function getTransactionStatus(orderCode) {
  // 1. Tìm trong DB trước
  const result = await pool.query(
    'SELECT id, user_id, status, amount FROM transactions WHERE order_id = $1 LIMIT 1',
    [orderCode]
  );

  if (result.rowCount === 0) return null;
  const transaction = result.rows[0];

  // 2. Nếu đã completed thì trả về luôn
  if (transaction.status === 'completed') {
    return transaction;
  }

  // 3. Nếu vẫn pending, chủ động hỏi PayOS xem thực tế thế nào
  try {
    const payosInfo = await payos.getPaymentLinkInformation(orderCode);
    console.log(`[DEBUG] Proactive check for order ${orderCode}: PayOS status = ${payosInfo.status}`);

    if (payosInfo.status === 'PAID') {
      // Nếu PayOS bảo đã trả tiền, mà DB mình chưa cập nhật -> Cập nhật ngay
      await processSuccessfulTransaction(transaction, payosInfo.amount);
      return { ...transaction, status: 'completed' };
    }
  } catch (err) {
    console.warn(`[PayOS Check Error] Không thể check status order ${orderCode}:`, err.message);
  }

  return transaction;
}


