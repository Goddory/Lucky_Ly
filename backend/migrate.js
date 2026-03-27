import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { pool } from './src/db/pool.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function runMigration() {
  const sqlPath = path.join(__dirname, 'database', 'fix_uuid_types.sql');
  
  if (!fs.existsSync(sqlPath)) {
    console.error(`Không tìm thấy file SQL tại: ${sqlPath}`);
    process.exit(1);
  }

  const sql = fs.readFileSync(sqlPath, 'utf8');

  console.log('--- Đang bắt đầu quá trình cập nhật Database ---');
  
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    console.log('Đang thực thi các lệnh SQL...');
    await client.query(sql);
    await client.query('COMMIT');
    console.log('✅ Chúc mừng! Cập nhật Database thành công.');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Lỗi khi thực thi script SQL:');
    console.error(err.message);
    if (err.detail) console.error(`Chi tiết: ${err.detail}`);
    if (err.hint) console.error(`Gợi ý: ${err.hint}`);
  } finally {
    client.release();
    await pool.end();
    process.exit(0);
  }
}

runMigration();
