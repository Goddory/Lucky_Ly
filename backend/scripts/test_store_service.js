import { pool } from '../src/db/pool.js';
import * as storeService from '../src/modules/store/store.service.js';

async function testStoreService() {
  try {
    console.log('Testing Apriori Dataset processing...');
    const result = await storeService.runApriori(0.1, 0.5);
    console.log(`Apriori Success! Found ${result.combos.length} combos based on ${result.transactionCount} transactions.`);
    
    // Testing load dataset to inventory (using the Marketing Admin user we created before "marketing@luckyly.com")
    // Wait, let's just do a dry run or pass user_id = 1
    const { rows } = await pool.query("SELECT user_id FROM users WHERE email = 'marketing@luckyly.com'");
    if (rows.length > 0) {
      const marketingUserId = rows[0].user_id;
      console.log('Testing Load Dataset to Inventory...');
      const invResult = await storeService.loadDatasetToInventory(marketingUserId);
      console.log(`Inventory Load Success! Inserted ${invResult.inserted} out of ${invResult.total} items.`);
    }

  } catch (err) {
    console.error('Error during test:', err);
  } finally {
    pool.end();
  }
}

testStoreService();
