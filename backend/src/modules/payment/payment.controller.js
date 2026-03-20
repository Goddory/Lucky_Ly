import { createMoMoPayment } from '../../utils/momoService.js';
import { createVNPayPayment, verifyVNPayCallback } from '../../utils/vnpayService.js';

export const createPaymentUrl = async (req, res, next) => {
  try {
    const { amount, orderInfo } = req.body;
    
    // In a real application, you would create an order in the database here
    const orderId = `MOMO_${Date.now()}_${Math.floor(Math.random() * 10000)}`;

    const momoResponse = await createMoMoPayment({
      orderId,
      orderInfo: orderInfo || 'Thanh toan don hang Lucky Ly',
      amount
    });

    res.status(200).json({
      message: 'MoMo payment URL created successfully',
      payUrl: momoResponse.payUrl,
      orderId
    });
  } catch (error) {
    next(error);
  }
};

export const ipnCallback = async (req, res, next) => {
  try {
    // MoMo calls this API when the payment is completed
    const payload = req.body;
    
    // In a real application, you should verify the signature from MoMo
    // using your secretKey to ensure the request is actually from MoMo
    
    console.log('--- MoMo IPN Callback ---');
    console.log('Order ID:', payload.orderId);
    console.log('Result Code:', payload.resultCode);
    console.log('Message:', payload.message);
    
    if (payload.resultCode === 0) {
      // Payment successful
      // Update order status in database to 'PAID'
      console.log('Payment Successful');
    } else {
      // Payment failed
      console.log('Payment Failed');
    }

    // Must return 204 to let MoMo know we received the callback
    res.status(204).send();
  } catch (error) {
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
    <title>Cổng Thanh Toán MoMo (Mô Phỏng)</title>
    <style>
      body { font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 0; display: flex; justify-content: center; align-items: center; height: 100vh; }
      .container { background-color: white; border-radius: 12px; padding: 30px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); text-align: center; max-width: 400px; width: 90%; }
      .momo-logo { background-color: #a50064; color: white; padding: 15px; border-radius: 12px 12px 0 0; margin: -30px -30px 20px -30px; font-size: 20px; font-weight: bold; }
      .amount { font-size: 32px; font-weight: bold; color: #a50064; margin: 20px 0; }
      .btn { background-color: #a50064; color: white; border: none; padding: 15px 20px; border-radius: 8px; font-size: 16px; font-weight: bold; cursor: pointer; width: 100%; margin-top: 20px; }
      .btn:hover { background-color: #8c0054; }
      .info { color: #666; font-size: 14px; margin-bottom: 5px; }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="momo-logo">Ví MoMo (Môi trường Test)</div>
      <div class="info">Đơn hàng: <b>${orderInfo}</b></div>
      <div class="info">Mã ĐH: ${orderId}</div>
      <div class="amount">${new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount)}</div>
      
      <form action="/api/payment/momo/mock-process" method="POST">
        <input type="hidden" name="orderId" value="${orderId}">
        <input type="hidden" name="amount" value="${amount}">
        <button type="submit" class="btn">Xác Nhận Thanh Toán</button>
      </form>
    </div>
  </body>
  </html>
  `;
  res.send(html);
};

export const processMockPayment = async (req, res) => {
  const { orderId, amount } = req.body;
  
  // Fake call to our own callback API
  try {
    await fetch('http://127.0.0.1:4000/api/payment/momo/callback', {
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
