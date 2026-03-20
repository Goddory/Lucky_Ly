-- Bảng lưu lịch sử giao dịch nạp tiền
CREATE TABLE IF NOT EXISTS transactions (
  id            SERIAL PRIMARY KEY,
  user_id       UUID         NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  order_code    BIGINT       UNIQUE NOT NULL,
  amount        NUMERIC(15,2) NOT NULL,
  type          VARCHAR(20)  NOT NULL DEFAULT 'deposit',   -- 'deposit' | 'withdraw'
  status        VARCHAR(20)  NOT NULL DEFAULT 'pending',   -- 'pending' | 'completed' | 'cancelled'
  description   TEXT,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ
);

-- Index để tra cứu nhanh theo user
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_order_code ON transactions(order_code);

-- Đảm bảo wallets có cột updated_at (nếu chưa có)
ALTER TABLE wallets ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;
