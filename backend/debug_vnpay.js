import { createVNPayPayment } from './src/utils/vnpayService.js';
import { env } from './src/config/env.js';

import fs from 'fs';

async function test() {
  const params = {
    orderId: '1742445017000',
    orderInfo: 'Nap tien Lucky Ly',
    amount: 50000,
    ipAddr: '127.0.0.1'
  };
  const result = await createVNPayPayment(params);
  console.log('--- VNPay Debug ---');
  console.log('TMN CODE:', env.vnpay.tmnCode || 'MO4V1NJO');
  fs.writeFileSync('debug_url.txt', result.payUrl);
  console.log('Full URL saved to debug_url.txt');
}
test();
