import { createMoMoPayment } from './src/utils/momoService.js';

async function test() {
  try {
    console.log('Testing MoMo Service...');
    const res = await createMoMoPayment({
      orderId: 'TEST_' + Date.now(),
      orderInfo: 'Test Order',
      amount: 50000
    });
    console.log('Success:', res);
  } catch (err) {
    console.error('Error:', err);
  }
}

test();
