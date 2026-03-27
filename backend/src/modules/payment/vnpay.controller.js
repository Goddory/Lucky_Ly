import { createVNPayPayment, verifyVNPayCallback } from '../../utils/vnpayService.js';
import { pool } from '../../db/pool.js';

export const createVNPayUrl = async (req, res, next) => {
  try {
    const { amount, orderInfo } = req.body;
    const userId = req.user.id;
    const ipAddr = req.headers['x-forwarded-for'] || req.connection?.remoteAddress || req.socket?.remoteAddress || '127.0.0.1';
    
    const parsedAmount = parseInt(amount);
    if (isNaN(parsedAmount)) {
      return res.status(400).json({ message: 'Invalid amount' });
    }

    const orderId = `${Date.now()}${Math.floor(Math.random() * 10000)}`;

    console.log('DEBUG: Creating transaction for user:', userId, 'order:', orderId);

    // Save pending transaction to database
    try {
        await pool.query(
          `INSERT INTO transactions (user_id, order_id, amount, provider, status) 
           VALUES ($1, $2, $3, $4, $5)`,
          [userId, orderId, parsedAmount, 'vnpay', 'pending']
        );
        console.log('DEBUG: Transaction row inserted successfully');
    } catch (dbError) {
        console.error('DEBUG: DB INSERT ERROR:', dbError.message);
        throw dbError;
    }

    console.log('DEBUG: Calling createVNPayPayment...');
    const vnpResponse = await createVNPayPayment({
      orderId,
      orderInfo: orderInfo || 'Nap tien Lucky Ly',
      amount: parsedAmount,
      ipAddr
    });

    console.log('DEBUG: VNPay URL created:', vnpResponse.payUrl);

    res.status(200).json({
      message: 'VNPay payment URL created successfully',
      payUrl: vnpResponse.payUrl,
      orderId
    });
  } catch (error) {
    console.error("VNPAY CREATE ERROR:", error);
    next(error);
  }
};

export const vnpayReturn = async (req, res, next) => {
  try {
    let vnp_Params = req.query;
    const isVerified = verifyVNPayCallback(vnp_Params);
    
    if(isVerified){
        const orderId = vnp_Params['vnp_TxnRef'];
        if(vnp_Params['vnp_ResponseCode'] === '00'){
            // Payment success. Update transaction and wallet
            const client = await pool.connect();
            try {
              await client.query('BEGIN');
              const txRes = await client.query(
                "UPDATE transactions SET status = 'success', updated_at = NOW() WHERE order_id = $1 AND status = 'pending' RETURNING user_id, amount",
                [orderId]
              );
              if (txRes.rows.length > 0) {
                const { user_id, amount } = txRes.rows[0];
                await client.query(
                  "UPDATE wallets SET balance = balance + $1 WHERE user_id = $2",
                  [amount, user_id]
                );
              }
              await client.query('COMMIT');
            } catch (err) {
              await client.query('ROLLBACK');
              console.error('Error updating transaction in vnpayReturn:', err);
            } finally {
              client.release();
            }

            return res.send(`
              <!DOCTYPE html>
              <html>
              <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <title>Thanh Toán Thành Công</title>
                <style>
                  body { font-family: Arial, sans-serif; background-color: #f4f4f4; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
                  .container { background-color: white; border-radius: 12px; padding: 40px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); text-align: center; }
                  .icon { color: #4CAF50; font-size: 60px; margin-bottom: 20px; }
                  h2 { color: #333; margin-bottom: 10px;}
                  p { color: #666; }
                  .btn { display: inline-block; background: #0C8DB8; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; margin-top: 20px; font-weight: bold;}
                </style>
              </head>
              <body>
                <div class="container">
                  <div class="icon">✓</div>
                  <h2>Thanh Toán Thành Công!</h2>
                  <p>Mã giao dịch: ${vnp_Params['vnp_TxnRef']}</p>
                  <p>Số tiền: ${new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(vnp_Params['vnp_Amount'] / 100)}</p>
                  <a href="#" class="btn" onclick="window.close();">Đóng trang này</a>
                </div>
              </body>
              </html>
            `);
        } else {
            return res.send('<div style="text-align:center; margin-top: 50px; font-family: Arial;"><h2>Thanh toán thất bại hoặc bị hủy.</h2><a href="#" style="background:#dc3545;color:white;padding:10px 20px;text-decoration:none;border-radius:5px;" onclick="window.close();">Đóng</a></div>');
        }
    } else {
        return res.send('<div style="text-align:center; margin-top: 50px; font-family: Arial;"><h2>Dữ liệu không hợp lệ (Sai Checksum)</h2></div>');
    }
  } catch (error) {
    next(error);
  }
};

export const vnpayIpn = async (req, res, next) => {
  try {
    let vnp_Params = req.query;
    const isVerified = verifyVNPayCallback(vnp_Params);
    
    if(isVerified){
        const orderId = vnp_Params['vnp_TxnRef'];
        const rspCode = vnp_Params['vnp_ResponseCode'];
        
        if(rspCode === '00'){
            console.log('VNPay IPN: Payment Successful for order:', orderId);
        } else {
            console.log('VNPay IPN: Payment Failed for order:', orderId);
        }
        res.status(200).json({RspCode: '00', Message: 'Confirm Success'});
    } else {
        res.status(200).json({RspCode: '97', Message: 'Fail checksum'});
    }
  } catch (error) {
    next(error);
  }
};

export const getTransactionHistory = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const result = await pool.query(
      "SELECT * FROM transactions WHERE user_id = $1 ORDER BY created_at DESC",
      [userId]
    );
    res.status(200).json({
      message: 'Success',
      data: result.rows
    });
  } catch (error) {
    next(error);
  }
};
