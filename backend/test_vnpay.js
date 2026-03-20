import { createVNPayPayment } from './src/utils/vnpayService.js';
import fs from 'fs';

async function test() {
  const res = await createVNPayPayment({
    orderId: "123456",
    orderInfo: "Nap tien Lucky Ly",
    amount: 50000,
    ipAddr: "127.0.0.1" 
  });
  console.log(res.payUrl);
}

test();
