import { pool } from './src/db/pool.js';
import * as storeService from './src/modules/store/store.service.js';

async function test() {
  const testUserId = '00000000-0000-0000-0000-000000000001';
  const creatorId = '00000000-0000-0000-0000-000000000002';
  
  try {
    // Setup: Clean up and create test users/wallets
    await pool.query('DELETE FROM wallets WHERE user_id IN ($1, $2)', [testUserId, creatorId]);
    await pool.query('DELETE FROM store_items WHERE created_by = $1', [creatorId]);
    
    await pool.query("INSERT INTO users (user_id, email, password_hash, full_name, role) VALUES ($1, 'test@test.com', 'pw', 'Test User', 'user') ON CONFLICT (user_id) DO NOTHING", [testUserId]);
    await pool.query("INSERT INTO users (user_id, email, password_hash, full_name, role) VALUES ($1, 'creator@test.com', 'pw', 'Creator User', 'store_creator') ON CONFLICT (user_id) DO NOTHING", [creatorId]);
    
    await pool.query("INSERT INTO wallets (user_id, balance, currency, status) VALUES ($1, 100000, 'VND', 'ACTIVE')", [testUserId]);
    await pool.query("INSERT INTO wallets (user_id, balance, currency, status) VALUES ($1, 0, 'VND', 'ACTIVE')", [creatorId]);
    
    // Create an item
    const itemId = '00000000-0000-0000-0000-000000000003';
    await pool.query("INSERT INTO store_items (item_id, item_name, price, stock, category, created_by) VALUES ($1, 'Test Item', 25000, 10, 'Thiệp', $2)", [itemId, creatorId]);
    
    console.log('--- BEFORE CHECKOUT ---');
    const b1 = await pool.query('SELECT balance FROM wallets WHERE user_id = $1', [testUserId]);
    console.log('Buyer Balance:', b1.rows[0].balance);
    
    // Test checkout
    console.log('Performing checkout...');
    const result = await storeService.checkoutCart(testUserId, [itemId]);
    console.log('Result:', result);
    
    console.log('--- AFTER CHECKOUT ---');
    const b2 = await pool.query('SELECT balance FROM wallets WHERE user_id = $1', [testUserId]);
    const b3 = await pool.query('SELECT balance FROM wallets WHERE user_id = $1', [creatorId]);
    console.log('Buyer Balance:', b2.rows[0].balance);
    console.log('Creator Balance:', b3.rows[0].balance);
    
    if (Number(b2.rows[0].balance) === 75000) {
      console.log('SUCCESS: Balance deducted correctly.');
    } else {
      console.log('FAILURE: Balance NOT deducted correctly.');
    }

  } catch (err) {
    console.error('Test failed:', err);
  } finally {
    process.exit(0);
  }
}

test();
