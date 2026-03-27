-- Lucky_Ly Neon PostgreSQL Schema
-- Consolidated from existing migrations and 6-role team plan

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Clean up existing tables (Optional - use with caution in production)
-- Clean up existing tables to ensure a clean install of the 6-role schema
DROP TABLE IF EXISTS promotion_usage CASCADE;
DROP TABLE IF EXISTS vouchers CASCADE;
DROP TABLE IF EXISTS promotions CASCADE;
DROP TABLE IF EXISTS gacha_logs CASCADE;
DROP TABLE IF EXISTS drop_rates CASCADE;
DROP TABLE IF EXISTS minigames CASCADE;
DROP TABLE IF EXISTS reports CASCADE;
DROP TABLE IF EXISTS gift_messages CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS items CASCADE;
DROP TABLE IF EXISTS stores CASCADE;
DROP TABLE IF EXISTS system_logs CASCADE;
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP TABLE IF EXISTS chat_room_participants CASCADE;
DROP TABLE IF EXISTS chat_rooms CASCADE;
DROP TABLE IF EXISTS gift_receivers CASCADE;
DROP TABLE IF EXISTS gifts CASCADE;
DROP TABLE IF EXISTS friends CASCADE;
DROP TABLE IF EXISTS designs CASCADE;
DROP TABLE IF EXISTS auth_refresh_tokens CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-------------------------------------------------------------------------------
-- 0. CORE IDENTITY (USERS)
-------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    user_id UUID DEFAULT gen_random_uuid() UNIQUE, -- For compatibility with UUID-based logic
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    full_name VARCHAR(255),
    role VARCHAR(50) DEFAULT 'Customer', -- 'Customer', 'Admin', 'Moderator', 'Store_Owner'
    student_id VARCHAR(100), -- Null if not a student
    wallet_balance DECIMAL(15, 2) DEFAULT 0.00,
    is_searchable BOOLEAN DEFAULT TRUE,
    is_banned BOOLEAN DEFAULT FALSE,
    fcm_token TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-------------------------------------------------------------------------------
-- 1. AUTH & SESSION
-------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS auth_refresh_tokens (
    token_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    device_id VARCHAR(255),
    device_name VARCHAR(255),
    platform VARCHAR(50),
    user_agent TEXT,
    ip_address TEXT,
    last_used_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    replaced_by UUID REFERENCES auth_refresh_tokens(token_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-------------------------------------------------------------------------------
-- 2. SOCIAL & CHAT
-------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS friends (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    friend_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'accepted', 'declined'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_friendship UNIQUE (user_id, friend_id)
);

CREATE TABLE IF NOT EXISTS chat_rooms (
    id SERIAL PRIMARY KEY,
    room_type VARCHAR(20) DEFAULT 'private', -- 'private', 'group'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS chat_room_participants (
    id SERIAL PRIMARY KEY,
    room_id INTEGER NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_room_participant UNIQUE (room_id, user_id)
);

-------------------------------------------------------------------------------
-- 3. STORE & ITEMS (Role: Creator/Store)
-------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS stores (
    id SERIAL PRIMARY KEY,
    owner_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    store_name VARCHAR(255) NOT NULL,
    revenue DECIMAL(15, 2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS items (
    id SERIAL PRIMARY KEY,
    store_id INTEGER NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    item_name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    item_type VARCHAR(50) DEFAULT 'Gift', -- 'Gift', 'Badge', 'Effect', 'Envelope'
    image_url TEXT,
    config JSONB, -- For AR/Visual custom config
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-------------------------------------------------------------------------------
-- 4. TRANSACTIONS & GIFTS (Role: Customer)
-------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS transactions (
    id SERIAL PRIMARY KEY,
    sender_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id INTEGER REFERENCES users(id) ON DELETE SET NULL, -- Can be null for link-based gifts
    item_id INTEGER REFERENCES items(id) ON DELETE SET NULL,
    amount DECIMAL(15, 2) NOT NULL, -- Amount paid or value of gift
    tx_type VARCHAR(50) DEFAULT 'gift', -- 'gift', 'purchase', 'topup', 'withdraw'
    status VARCHAR(20) DEFAULT 'completed', -- 'pending', 'completed', 'cancelled'
    qr_token VARCHAR(255) UNIQUE,
    deep_link VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- For messages attached to gifts/transactions (Role: Moderator)
CREATE TABLE IF NOT EXISTS gift_messages (
    id SERIAL PRIMARY KEY,
    transaction_id INTEGER NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    message_text TEXT,
    ai_flag VARCHAR(20) DEFAULT 'Clean', -- 'Clean', 'Spam', 'Hate_Speech'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-------------------------------------------------------------------------------
-- 5. MODERATION & REPORTS (Role: Moderator)
-------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reports (
    id SERIAL PRIMARY KEY,
    message_id INTEGER REFERENCES gift_messages(id) ON DELETE CASCADE,
    reporter_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    reason TEXT,
    status VARCHAR(20) DEFAULT 'Pending', -- 'Pending', 'Resolved', 'Dismissed'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-------------------------------------------------------------------------------
-- 6. MINIGAMES & GACHA (Role: Minigame Manager)
-------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS minigames (
    id SERIAL PRIMARY KEY,
    game_name VARCHAR(100) NOT NULL, -- 'Lucky Wheel', 'Gacha'
    description TEXT,
    cost_per_play DECIMAL(10, 2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS drop_rates (
    id SERIAL PRIMARY KEY,
    game_id INTEGER NOT NULL REFERENCES minigames(id) ON DELETE CASCADE,
    item_id INTEGER REFERENCES items(id) ON DELETE CASCADE,
    probability_weight FLOAT NOT NULL DEFAULT 1.0
);

CREATE TABLE IF NOT EXISTS gacha_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    game_id INTEGER NOT NULL REFERENCES minigames(id) ON DELETE CASCADE,
    won_item_id INTEGER REFERENCES items(id), -- Null if player lost/got nothing
    played_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-------------------------------------------------------------------------------
-- 7. PROMOTIONS & VOUCHERS (Role: Marketing/Student)
-------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS promotions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    target_audience VARCHAR(50) DEFAULT 'All', -- 'All', 'Student'
    discount_type VARCHAR(20) DEFAULT 'Percent', -- 'Percent', 'Fixed'
    discount_value DECIMAL(10, 2) NOT NULL,
    starts_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS vouchers (
    id SERIAL PRIMARY KEY,
    promotion_id INTEGER REFERENCES promotions(id) ON DELETE CASCADE,
    code VARCHAR(50) UNIQUE NOT NULL,
    max_uses INTEGER DEFAULT 1,
    current_uses INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS promotion_usage (
    id SERIAL PRIMARY KEY,
    voucher_id INTEGER REFERENCES vouchers(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    transaction_id INTEGER REFERENCES transactions(id) ON DELETE CASCADE,
    used_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-------------------------------------------------------------------------------
-- 8. SYSTEM LOGS & AUDIT (Role: Admin)
-------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS system_logs (
    id SERIAL PRIMARY KEY,
    admin_id INTEGER REFERENCES users(id),
    action_type VARCHAR(50) NOT NULL, -- 'Topup', 'Withdraw', 'Ban', 'Config_Change'
    target_id INTEGER, -- ID of user/item/store being affected
    amount DECIMAL(15, 2),
    details TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-------------------------------------------------------------------------------
-- 9. MISC (STUDIO/DESIGNS)
-------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS designs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) DEFAULT 'Unnamed Design',
    type VARCHAR(50) NOT NULL, -- 'envelope', 'ar_item'
    config JSONB NOT NULL,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-------------------------------------------------------------------------------
-- TRIGGERS & FUNCTIONS
-------------------------------------------------------------------------------

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_modtime BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_friends_modtime BEFORE UPDATE ON friends FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_chat_rooms_modtime BEFORE UPDATE ON chat_rooms FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_designs_modtime BEFORE UPDATE ON designs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-------------------------------------------------------------------------------
-- INDEXES
-------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_student_id ON users(student_id);
CREATE INDEX IF NOT EXISTS idx_transactions_sender ON transactions(sender_id);
CREATE INDEX IF NOT EXISTS idx_transactions_receiver ON transactions(receiver_id);
CREATE INDEX IF NOT EXISTS idx_vouchers_code ON vouchers(code);
CREATE INDEX IF NOT EXISTS idx_items_store ON items(store_id);
