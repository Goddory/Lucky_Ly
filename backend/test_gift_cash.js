import { pool } from './src/db/pool.js';
import * as giftsService from './src/modules/gifts/gifts.service.js';

async function verifyGiftCash() {
  const senderId = '00000000-0000-0000-0000-000000000001';
  const receiverId = '00000000-0000-0000-0000-000000000002';
  const amount = 50000;
  
  try {
    console.log('--- TEST: GIFT CASH TRANSFER ---');
    
    // Setup users
    await pool.query("INSERT INTO users (user_id, username, email, password_hash, full_name, role) VALUES ($1, 'sender', 'sender@test.com', 'pw', 'Sender', 'user') ON CONFLICT (user_id) DO NOTHING", [senderId]);
    await pool.query("INSERT INTO users (user_id, username, email, password_hash, full_name, role) VALUES ($1, 'receiver', 'receiver@test.com', 'pw', 'Receiver', 'user') ON CONFLICT (user_id) DO NOTHING", [receiverId]);
    
    // Setup wallets
    await pool.query("INSERT INTO wallets (user_id, balance) VALUES ($1, 200000) ON CONFLICT (user_id) DO UPDATE SET balance = 200000", [senderId]);
    await pool.query("INSERT INTO wallets (user_id, balance) VALUES ($1, 0) ON CONFLICT (user_id) DO UPDATE SET balance = 0", [receiverId]);
    
    // 1. Send Gift
    console.log('1. Sender sending gift with 50,000 VND...');
    const gift = await giftsService.createGift(senderId, {
      receiverEmail: 'receiver@test.com',
      theme: 'tet',
      modelId: 'tet_lixi_red',
      message: 'Happy New Year!',
      cashAmount: amount
    });
    
    const sWallet = await pool.query('SELECT balance FROM wallets WHERE user_id = $1', [senderId]);
    console.log('Sender Balance after sending:', sWallet.rows[0].balance);
    if (Number(sWallet.rows[0].balance) === 150000) {
      console.log('✅ Sender balance deducted correctly.');
    } else {
      console.error('❌ Sender balance deduction failed.');
    }
    
    // 2. Open Gift
    console.log('2. Receiver opening gift...');
    await giftsService.markAsOpened(gift.id, 'receiver@test.com');
    
    const rWallet = await pool.query('SELECT balance FROM wallets WHERE user_id = $1', [receiverId]);
    console.log('Receiver Balance after opening:', rWallet.rows[0].balance);
    if (Number(rWallet.rows[0].balance) === 50000) {
      console.log('✅ Receiver balance credited correctly.');
    } else {
      console.error('❌ Receiver balance credit failed.');
    }
    
    // 3. Check Transactions
    const txs = await pool.query('SELECT * FROM transactions WHERE sender_id = $1 OR receiver_id = $1 ORDER BY created_at DESC LIMIT 2', [senderId]);
    console.log(`Found ${txs.rowCount} transactions related to sender.`);

    console.log('--- TEST FINISHED ---');
  } catch (err) {
    console.error('Test Error:', err);
  } finally {
    process.exit(0);
  }
}

verifyGiftCash();
