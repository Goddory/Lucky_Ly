-- Store Module Migration for Lucky Ly
-- Tạo các bảng cho module Cửa hàng / Nhà sáng tạo quà ảo

-- 1) Store Items: Danh sách vật phẩm ảo trong cửa hàng
CREATE TABLE IF NOT EXISTS store_items (
    item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_name VARCHAR(200) NOT NULL,
    category VARCHAR(100) NOT NULL,
    effect_type VARCHAR(100) DEFAULT 'none',
    price NUMERIC(18,2) NOT NULL CHECK (price >= 0),
    stock INTEGER NOT NULL DEFAULT 0,
    thumbnail_url VARCHAR(1500),
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_store_item_creator
        FOREIGN KEY (created_by) REFERENCES users(user_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

-- 2) Store Transactions: Lịch sử giao dịch bán quà
CREATE TABLE IF NOT EXISTS store_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    buyer_id UUID NOT NULL,
    items JSONB NOT NULL,
    total_amount NUMERIC(18,2) NOT NULL CHECK (total_amount > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_store_tx_buyer
        FOREIGN KEY (buyer_id) REFERENCES users(user_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- 3) Store Combos: Kết quả thuật toán Apriori - gợi ý combo
CREATE TABLE IF NOT EXISTS store_combos (
    combo_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    items JSONB NOT NULL,
    support NUMERIC(6,4) NOT NULL,
    confidence NUMERIC(6,4) NOT NULL,
    lift NUMERIC(8,4) NOT NULL,
    bundle_name VARCHAR(200),
    discount_percent INTEGER DEFAULT 10,
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_store_items_category ON store_items(category);
CREATE INDEX IF NOT EXISTS idx_store_items_created_by ON store_items(created_by);
CREATE INDEX IF NOT EXISTS idx_store_transactions_buyer ON store_transactions(buyer_id);
CREATE INDEX IF NOT EXISTS idx_store_transactions_created ON store_transactions(created_at);

-- Seed tài khoản store_creator (lylylylyly@gmail.com / lylylylyly)
-- Password hash for 'lylylylyly' with bcrypt rounds=12
-- Note: Chạy script seed_store_creator.js để tạo hash đúng
