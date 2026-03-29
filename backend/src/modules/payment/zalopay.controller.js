import * as zaloPayService from '../../utils/zalopayService.js';
import { pool } from '../../db/pool.js';

/**
 * Request ZaloPay payment URL
 */
export const createZaloPayUrl = async (req, res, next) => {
  try {
    const { amount, orderInfo, returnUrl } = req.body;
    const userId = req.user.userId;
    
    const parsedAmount = parseInt(amount);
    if (isNaN(parsedAmount)) {
      return res.status(400).json({ message: 'Invalid amount' });
    }

    const orderId = `${Date.now()}${Math.floor(Math.random() * 1000)}`;

    // Save pending transaction with return_url
    await pool.query(
      `INSERT INTO transactions (sender_id, order_id, amount, provider, status, tx_type, return_url) 
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [userId, orderId, parsedAmount, 'zalopay', 'pending', 'topup', returnUrl]
    );

    const zpResponse = await zaloPayService.createZaloPayOrder({
      amount: parsedAmount,
      orderId,
      description: orderInfo || `Lucky Ly - Payment #${orderId}`,
      appUser: `user_${userId}`
    });

    if (zpResponse.return_code !== 1) {
       throw new Error(`ZaloPay Error: ${zpResponse.return_message}`);
    }

    res.status(200).json({
      message: 'ZaloPay payment URL created successfully',
      payUrl: zpResponse.order_url,
      orderId,
      app_trans_id: zpResponse.app_trans_id
    });
  } catch (error) {
    console.error("ZALOPAY CREATE ERROR:", error);
    next(error);
  }
};

/**
 * Handle ZaloPay callback (IPN)
 */
export const zaloPayCallback = async (req, res) => {
  let result = {};
  try {
    const { data: dataStr, mac: reqMac } = req.body;

    const isVerified = zaloPayService.verifyZaloPayCallback(dataStr, reqMac);

    if (!isVerified) {
      result.return_code = -1;
      result.return_message = 'mac not equal';
    } else {
      // payment success
      const dataJson = JSON.parse(dataStr);
      const appTransId = dataJson['app_trans_id'];
      
      // Extract original orderId from app_trans_id (format: YYMMDD_orderId)
      const orderId = appTransId.split('_')[1];

      const client = await pool.connect();
      try {
        await client.query('BEGIN');
        const txRes = await client.query(
          "UPDATE transactions SET status = 'success', updated_at = NOW() WHERE order_id = $1 AND status = 'pending' RETURNING sender_id, amount",
          [orderId]
        );
        
        if (txRes.rows.length > 0) {
          const { sender_id, amount } = txRes.rows[0];
          // Upsert wallet: create if not exists
          await client.query(
            `INSERT INTO wallets (user_id, balance, currency, status) VALUES ($1, 0, 'VND', 'ACTIVE')
             ON CONFLICT (user_id) DO NOTHING`,
            [sender_id]
          );
          await client.query(
            "UPDATE wallets SET balance = balance + $1 WHERE user_id = $2",
            [amount, sender_id]
          );
        }
        await client.query('COMMIT');
      } catch (err) {
        await client.query('ROLLBACK');
        console.error('Error updating transaction in zaloPayCallback:', err);
      } finally {
        client.release();
      }

      result.return_code = 1;
      result.return_message = 'success';
    }
  } catch (ex) {
    console.error('ZaloPay Callback error:', ex.message);
    result.return_code = 0;
    result.return_message = ex.message;
  }

  res.json(result);
};

/**
 * Handle ZaloPay return (Redirect)
 */
export const zaloPayReturn = async (req, res, next) => {
  try {
    const { amount, apptransid, status } = req.query;

    // Fetch return_url from transaction
    const orderId = apptransid.split('_')[1];
    const txRes = await pool.query("SELECT return_url FROM transactions WHERE order_id = $1", [orderId]);
    const returnUrl = txRes.rows[0]?.return_url || '#';
    
    // ZaloPay status: 1 is success
    if (status === '1') {
      return res.send(`
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <meta http-equiv="refresh" content="2;url=${returnUrl}">
          <title>Thanh Toán ZaloPay Thành Công</title>
          <style>
            body { font-family: Arial, sans-serif; background-color: #f4f4f4; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
            .container { background-color: white; border-radius: 12px; padding: 40px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); text-align: center; max-width: 400px; width: 90%; }
            .icon { color: #4CAF50; font-size: 60px; margin-bottom: 20px; }
            h2 { color: #333; margin-bottom: 10px;}
            p { color: #666; font-size: 14px; line-height: 1.6; }
            .amount { font-size: 20px; font-weight: bold; color: #0068FF; margin: 15px 0; }
            .btn { display: inline-block; background: #0068FF; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; margin-top: 20px; font-weight: bold;}
            .timer { font-size: 12px; color: #999; margin-top: 10px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="icon">✓</div>
            <h2>Thanh Toán Thành Công!</h2>
            <p>Giao dịch qua ZaloPay đã được ghi nhận.</p>
            <p class="amount">${new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount || 0)}</p>
            <p>Mã giao dịch: ${apptransid}</p>
            <a href="${returnUrl}" class="btn">Quay lại ứng dụng</a>
            <p class="timer">Đang tự động quay lại trong giây lát...</p>
          </div>
          <script>
            setTimeout(() => {
              window.location.href = "${returnUrl}";
            }, 1500);
          </script>
        </body>
        </html>
      `);
    } else {
      return res.send(`
        <div style="text-align:center; margin-top: 50px; font-family: Arial;">
          <h2>Thanh toán ZaloPay thất bại hoặc bị hủy.</h2>
          <a href="${returnUrl}" style="background:#dc3545;color:white;padding:10px 20px;text-decoration:none;border-radius:5px;">Quay lại</a>
          <script>
            setTimeout(() => {
              window.location.href = "${returnUrl}";
            }, 2000);
          </script>
        </div>
      `);
    }
  } catch (error) {
    next(error);
  }
};

/**
 * Check ZaloPay order status
 */
export const checkZaloPayStatus = async (req, res, next) => {
  try {
    const { app_trans_id } = req.body;
    const result = await zaloPayService.queryZaloPayOrderStatus(app_trans_id);
    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};
