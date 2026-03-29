import { pool } from '../src/db/pool.js';
import { loadDatasetToInventory } from '../src/modules/store/store.service.js';

async function fixStoreItems() {
  const client = await pool.connect();
  try {
    const { rows } = await client.query("SELECT user_id FROM users WHERE email = 'lylylylyly@gmail.com'");
    if (rows.length === 0) {
      console.log('Creator lylylylyly@gmail.com not found!');
      return;
    }
    const myCreatorId = rows[0].user_id;

    console.log(`Creator found: ${myCreatorId}`);
    
    // Update all existing items to this creator
    const res = await client.query('UPDATE store_items SET created_by = $1', [myCreatorId]);
    console.log(`Updated ${res.rowCount} items to creator ${myCreatorId}.`);
    
    // Also try to load any remaining dataset items
    const invResult = await loadDatasetToInventory(myCreatorId);
    console.log(`Loaded dataset: inserted ${invResult.inserted} out of ${invResult.total} items.`);
    
    // Also populate some mock store_transactions so revenue works!
    const txnCheck = await client.query('SELECT COUNT(*) FROM store_transactions');
    if (parseInt(txnCheck.rows[0].count) === 0) {
      const { rows: users } = await client.query('SELECT user_id FROM users LIMIT 1');
      if (users.length > 0) {
        const defaultBuyer = users[0].user_id;
        await client.query(`
          INSERT INTO store_transactions (buyer_id, items, total_amount, created_at)
          VALUES 
          ($1, '[{"name": "Hoa Hồng Virtual", "price": 45000, "quantity": 1}]', 45000, NOW() - INTERVAL '2 days'),
          ($1, '[{"name": "Thiệp Chúc Mừng", "price": 25000, "quantity": 2}, {"name": "Gấu Bông AR", "price": 120000, "quantity": 1}]', 170000, NOW() - INTERVAL '1 day'),
          ($1, '[{"name": "Bánh Kem Virtual", "price": 75000, "quantity": 1}]', 75000, NOW())
        `, [defaultBuyer]);
        console.log('Mock transactions inserted!');
      }
    }
    
  } catch(e) {
    console.error('Error:', e);
  } finally {
    client.release();
    pool.end();
  }
}
fixStoreItems();
