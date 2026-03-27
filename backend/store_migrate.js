import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { pool } from './src/db/pool.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function runMigration() {
  // Thay đổi đường dẫn để trỏ tới database/store_migration.sql
  // Chú ý: __dirname hiện tại là backend/, database/ nằm ở thư mục cha
  const sqlPath = path.resolve(__dirname, '..', 'database', 'store_migration.sql');
  
  if (!fs.existsSync(sqlPath)) {
    console.error(`Không tìm thấy file SQL tại: ${sqlPath}`);
    process.exit(1);
  }

  const sql = fs.readFileSync(sqlPath, 'utf8');

  console.log('--- Đang bắt đầu quá trình cập nhật Database cho Store Module ---');
  
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    console.log('Đang thực thi các lệnh SQL...');
    await client.query(sql);
    await client.query('COMMIT');
    console.log('✅ Chúc mừng! Tạo các bảng Store thành công.');
  } catch (err) {
    if (client) await client.query('ROLLBACK');
    console.error('❌ Lỗi khi thực thi script SQL:');
    console.error(err.message);
  } finally {
    if (client) client.release();
    await pool.end();
    process.exit(0);
  }
}

runMigration();
