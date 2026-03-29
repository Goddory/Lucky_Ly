import { createMoMoPayment } from '../../utils/momoService.js';
import { env } from '../../config/env.js';
import { pool } from '../../db/pool.js';
import crypto from 'crypto';

export const createPaymentUrl = async (req, res, next) => {
  try {
    const { amount, orderInfo } = req.body;
    const userId = req.user?.userId; // Fixed: authMiddleware sets req.user.userId, not req.user.id
    
    if (!userId) {
        return res.status(401).json({ message: 'Unauthorized' });
    }

    const parsedAmount = parseInt(amount);
    if (isNaN(parsedAmount)) {
      return res.status(400).json({ message: 'Invalid amount' });
    }

    const orderId = `MOMO_${Date.now()}_${Math.floor(Math.random() * 10000)}`;

    // Save pending transaction to database
    await pool.query(
      `INSERT INTO transactions (sender_id, order_id, amount, provider, status, tx_type) 
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [userId, orderId, parsedAmount, 'momo', 'pending', 'topup']
    );

    if (env.momo.useMock) {
      console.log('Using MoMo Mock Flow');
      const mockPayUrl = `${req.protocol}://${req.get('host')}/api/payment/momo/mock-page?orderId=${orderId}&amount=${parsedAmount}&orderInfo=${encodeURIComponent(orderInfo || 'Lucky Ly Mock Payment')}`;
      return res.status(200).json({
        message: 'MoMo mock payment URL created successfully',
        payUrl: mockPayUrl,
        orderId
      });
    }

    const momoResponse = await createMoMoPayment({
      orderId,
      orderInfo: orderInfo || 'Thanh toan don hang Lucky Ly',
      amount: parsedAmount
    });

    res.status(200).json({
      message: 'MoMo payment URL created successfully',
      payUrl: momoResponse.payUrl,
      orderId
    });
  } catch (error) {
    console.error("MOMO CREATE ERROR:", error);
    next(error);
  }
};

export const ipnCallback = async (req, res, next) => {
  try {
    const payload = req.body;
    const { partnerCode, accessKey, secretKey } = env.momo;

    // Verify signature (optional but recommended)
    // Signature format for MoMo IPN: 
    // accessKey=$accessKey&amount=$amount&extraData=$extraData&message=$message&orderId=$orderId&orderInfo=$orderInfo&partnerCode=$partnerCode&requestId=$requestId&responseTime=$responseTime&resultCode=$resultCode&transId=$transId
    const { amount, extraData, message, orderId, orderInfo, requestId, responseTime, resultCode, transId, signature: momoSignature } = payload;
    
    const rawSignature = `accessKey=${accessKey}&amount=${amount}&extraData=${extraData}&message=${message}&orderId=${orderId}&orderInfo=${orderInfo}&partnerCode=${partnerCode}&requestId=${requestId}&responseTime=${responseTime}&resultCode=${resultCode}&transId=${transId}`;
    
    const checkSignature = crypto.createHmac('sha256', secretKey)
        .update(rawSignature)
        .digest('hex');

    if (checkSignature !== momoSignature) {
        console.error('MoMo IPN: Invalid Signature');
        // Still return 204 or error? MoMo docs say return 204 to stop retries if signature is wrong but we should log it.
        return res.status(400).json({ message: 'Invalid signature' });
    }

    console.log('--- MoMo IPN Callback ---');
    console.log('Order ID:', orderId);
    console.log('Result Code:', resultCode);
    
    if (resultCode == 0) {
      // Payment successful
      const client = await pool.connect();
      try {
        await client.query('BEGIN');
        const txRes = await client.query(
          "UPDATE transactions SET status = 'success', updated_at = NOW() WHERE order_id = $1 AND status = 'pending' RETURNING sender_id, amount",
          [orderId]
        );
        if (txRes.rows.length > 0) {
          const { sender_id, amount } = txRes.rows[0];
          // Upsert wallet: create if not exists, then update balance
          await client.query(
            `INSERT INTO wallets (user_id, balance, currency, status) VALUES ($1, 0, 'VND', 'ACTIVE')
             ON CONFLICT (user_id) DO NOTHING`,
            [sender_id]
          );
          await client.query(
            "UPDATE wallets SET balance = balance + $1 WHERE user_id = $2",
            [amount, sender_id]
          );
          console.log(`MoMo: Updated wallet for user ${sender_id} with amount ${amount}`);
        }
        await client.query('COMMIT');
      } catch (err) {
        await client.query('ROLLBACK');
        console.error('Error updating transaction in MoMo callback:', err);
      } finally {
        client.release();
      }
    } else {
      // Payment failed/cancelled
      await pool.query(
        "UPDATE transactions SET status = 'failed', updated_at = NOW() WHERE order_id = $1 AND status = 'pending'",
        [orderId]
      );
      console.log('MoMo Payment Failed');
    }

    res.status(204).send();
  } catch (error) {
    console.error("MOMO CALLBACK ERROR:", error);
    next(error);
  }
};

export const renderMockMoMoPage = (req, res) => {
  const { orderId, amount, orderInfo } = req.query;
  
  const html = `
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Thanh Toán MoMo</title>
    <style>
      @import url('https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap');
      
      :root {
        --momo-magenta: #a50064;
        --momo-bg: #f5f5f5;
        --text-dark: #3c3c3c;
        --text-muted: #7d7d7d;
        --white: #ffffff;
      }

      body { 
        font-family: 'Roboto', sans-serif; 
        background-color: var(--momo-bg); 
        margin: 0; padding: 0; 
        display: flex; justify-content: center; align-items: center; 
        min-height: 100vh;
      }

      .main-container {
        display: flex;
        max-width: 900px;
        width: 95%;
        background: transparent;
        gap: 30px;
        padding-top: 40px;
      }

      .left-sidebar {
        flex: 1;
        display: flex;
        flex-direction: column;
        gap: 15px;
      }

      .card {
        background: var(--white);
        border-radius: 8px;
        padding: 24px;
        box-shadow: 0 4px 20px rgba(0,0,0,0.06);
      }

      .order-title {
        font-size: 18px;
        font-weight: 700;
        margin-bottom: 20px;
        color: var(--text-dark);
      }

      .info-row {
        margin-bottom: 20px;
      }

      .info-label {
        font-size: 13px;
        color: var(--text-muted);
        margin-bottom: 4px;
      }

      .info-value {
        font-size: 15px;
        font-weight: 700;
        color: var(--text-dark);
      }
      
      .amount-value {
        font-size: 24px;
        font-weight: 700;
        color: var(--text-dark);
      }

      .timer-card {
        background: #fff0f6;
        border: 1px solid #ffadd2;
        padding: 15px;
        text-align: center;
      }

      .timer-title {
        font-size: 13px;
        color: #ff4d94;
        margin-bottom: 12px;
      }

      .timer-display {
        display: flex;
        justify-content: center;
        gap: 10px;
      }

      .timer-box {
        background: var(--white);
        border-radius: 4px;
        width: 38px;
        height: 38px;
        display: flex;
        justify-content: center;
        align-items: center;
        color: #ff4d94;
        font-weight: 700;
        font-size: 18px;
        box-shadow: 0 2px 5px rgba(255, 77, 148, 0.2);
      }

      .timer-sep {
        font-size: 13px;
        color: #ff4d94;
        font-weight: 500;
        line-height: 38px;
      }

      .back-btn {
        text-align: center;
        margin-top: 10px;
        color: var(--momo-magenta);
        font-size: 14px;
        text-decoration: none;
        font-weight: 500;
      }

      .right-panel {
        flex: 1.5;
        background: var(--momo-magenta);
        border-radius: 12px;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        padding: 40px;
        color: var(--white);
        position: relative;
        overflow: hidden;
      }

      /* Decor pattern */
      .right-panel::before {
        content: "";
        position: absolute;
        top: 0; left: 0; right: 0; bottom: 0;
        background-image: radial-gradient(circle at 10px 10px, rgba(255,255,255,0.05) 2px, transparent 0);
        background-size: 30px 30px;
      }

      .qr-title {
        font-size: 20px;
        font-weight: 500;
        margin-bottom: 30px;
        z-index: 1;
      }

      .qr-white-box {
        background: var(--white);
        padding: 20px;
        border-radius: 15px;
        z-index: 1;
        box-shadow: 0 10px 40px rgba(0,0,0,0.15);
        margin-bottom: 25px;
      }

      .qr-code {
        width: 200px;
        height: 200px;
        background: url('https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=MOCK_MOMO_PAYMENT_${orderId}') center no-repeat;
        background-size: contain;
      }

      .qr-instruction {
        text-align: center;
        font-size: 13px;
        line-height: 1.6;
        max-width: 320px;
        z-index: 1;
        opacity: 0.95;
      }

      .process-btn {
        margin-top: 30px;
        background: var(--white);
        color: var(--momo-magenta);
        border: none;
        padding: 14px 40px;
        border-radius: 25px;
        font-weight: 700;
        font-size: 15px;
        cursor: pointer;
        z-index: 1;
        transition: all 0.3s;
        box-shadow: 0 4px 15px rgba(0,0,0,0.1);
      }

      .process-btn:hover { background: #f8f8f8; transform: scale(1.03); }
    </style>
  </head>
  <body>
    <div class="main-container">
      <div class="left-sidebar">
        <div class="card">
          <div class="order-title">Thông tin đơn hàng</div>
          
          <div class="info-row">
            <div class="info-label">Nhà cung cấp</div>
            <div class="info-value"><img src="https://static.mservice.io/img/logo-momo.png" width="20" style="vertical-align: middle; margin-right: 5px;"> MoMo Payment</div>
          </div>

          <div class="info-row">
            <div class="info-label">Mã đơn hàng</div>
            <div class="info-value">${orderId}</div>
          </div>

          <div class="info-row">
            <div class="info-label">Mô tả</div>
            <div class="info-value">${orderInfo || 'thanh toan ' + orderId.substring(0, 10)}</div>
          </div>

          <div class="info-row">
            <div class="info-label">Số tiền</div>
            <div class="amount-value">${new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount)}</div>
          </div>
        </div>

        <div class="card timer-card">
          <div class="timer-title">Đơn hàng sẽ hết hạn sau:</div>
          <div class="timer-display">
            <div class="timer-box" id="h">00</div>
            <div class="timer-sep">Giờ</div>
            <div class="timer-box" id="m">15</div>
            <div class="timer-sep">Phút</div>
            <div class="timer-box" id="s">00</div>
            <div class="timer-sep">Giây</div>
          </div>
        </div>

        <a href="#" class="back-btn" onclick="window.close()">Quay về</a>
      </div>

      <div class="right-panel">
        <div class="qr-title">Quét mã QR để thanh toán</div>
        <div class="qr-white-box">
          <div class="qr-code"></div>
        </div>
        <div class="qr-instruction">
           Sử dụng <b>App MoMo</b> hoặc ứng dụng camera hỗ trợ QR code để quét mã
           <br><br>
           Gặp khó khăn khi thanh toán? <span style="text-decoration: underline; cursor: pointer;">Xem Hướng dẫn</span>
        </div>
        
        <form action="/api/payment/momo/mock-process" method="POST">
          <input type="hidden" name="orderId" value="${orderId}">
          <input type="hidden" name="amount" value="${amount}">
          <button type="submit" class="process-btn">XÁC NHẬN THANH TOÁN</button>
        </form>
      </div>
    </div>

    <script>
      let h = 0, m = 15, s = 0;
      setInterval(() => {
        s--;
        if(s < 0) { 
           if (m > 0 || h > 0) { s = 59; m--; } 
           else { s = 0; }
        }
        if(m < 0) { 
           if (h > 0) { m = 59; h--; } 
           else { m = 0; }
        }
        document.getElementById('h').innerText = String(h).padStart(2, '0');
        document.getElementById('m').innerText = String(m).padStart(2, '0');
        document.getElementById('s').innerText = String(s).padStart(2, '0');
      }, 1000);
    </script>
  </body>
  </html>
  `;
  res.send(html);
};

export const processMockPayment = async (req, res) => {
  const { orderId, amount } = req.body;
  
  // Fake call to our own callback API
  try {
    const port = process.env.PORT || 4000;
    await fetch(`http://127.0.0.1:${port}/api/payment/momo/callback`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        orderId: orderId,
        resultCode: 0,
        message: "Successful"
      })
    });
  } catch(e) {
    console.log("Mock Webhook Error:", e);
  }

  const html = `
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
    </style>
  </head>
  <body>
    <div class="container">
      <div class="icon">✓</div>
      <h2>Thanh toán thành công!</h2>
      <p>Mã đơn hàng: ${orderId}</p>
      <p>Bạn có thể đóng trang web này và quay lại ứng dụng.</p>
    </div>
  </body>
  </html>
  `;
  res.send(html);
};

export const momoRedirect = async (req, res) => {
  try {
    const { orderId, resultCode, message, amount } = req.query;
    
    console.log('--- MoMo Redirect ---');
    console.log('Order ID:', orderId);
    console.log('Result Code:', resultCode);

    if (resultCode == 0) {
      return res.send(`
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>Thanh Toán MoMo Thành Công</title>
          <style>
            body { font-family: Arial, sans-serif; background-color: #f4f4f4; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
            .container { background-color: white; border-radius: 12px; padding: 40px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); text-align: center; max-width: 400px; width: 90%; }
            .icon { color: #4CAF50; font-size: 60px; margin-bottom: 20px; }
            h2 { color: #333; margin-bottom: 10px;}
            p { color: #666; margin: 5px 0; }
            .btn { display: inline-block; background: #A50064; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; margin-top: 20px; font-weight: bold;}
          </style>
        </head>
        <body>
          <div class="container">
            <div class="icon">✓</div>
            <h2>Thanh Toán Thành Công!</h2>
            <p>Mã đơn hàng: ${orderId}</p>
            <p>Số tiền: ${new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount)}</p>
            <p>Tài khoản của bạn sẽ được cập nhật trong giây lát.</p>
            <a href="#" class="btn" onclick="window.close();">Quay lại ứng dụng</a>
          </div>
        </body>
        </html>
      `);
    } else {
      return res.send(`
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>Thanh Toán MoMo Thất Bại</title>
          <style>
            body { font-family: Arial, sans-serif; background-color: #f4f4f4; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
            .container { background-color: white; border-radius: 12px; padding: 40px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); text-align: center; max-width: 400px; width: 90%; }
            .icon { color: #F44336; font-size: 60px; margin-bottom: 20px; }
            h2 { color: #333; margin-bottom: 10px;}
            p { color: #666; margin: 5px 0; }
            .btn { display: inline-block; background: #666; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; margin-top: 20px; font-weight: bold;}
          </style>
        </head>
        <body>
          <div class="container">
            <div class="icon">✕</div>
            <h2>Thanh Toán Không Thành Công</h2>
            <p>Lý do: ${message || 'Giao dịch bị hủy hoặc xảy ra lỗi.'}</p>
            <p>Mã đơn hàng: ${orderId}</p>
            <a href="#" class="btn" onclick="window.close();">Đóng trang này</a>
          </div>
        </body>
        </html>
      `);
    }
  } catch (error) {
    console.error("MOMO REDIRECT ERROR:", error);
    res.status(500).send("Internal Server Error");
  }
};
