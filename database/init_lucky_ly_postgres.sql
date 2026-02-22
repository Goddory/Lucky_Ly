-- Lucky Ly - Database schema (PostgreSQL)
-- Run with a role that can create extension/table/index.

-- Optional:
-- CREATE DATABASE lucky_ly;
-- \c lucky_ly;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'wallet_status') THEN
        CREATE TYPE wallet_status AS ENUM ('ACTIVE', 'LOCKED');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'transaction_status') THEN
        CREATE TYPE transaction_status AS ENUM ('ESCROW', 'CLAIMED', 'REFUNDED', 'FAILED');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type') THEN
        CREATE TYPE notification_type AS ENUM ('MONEY_SENT', 'MONEY_RECEIVED', 'REFUND', 'SYSTEM');
    END IF;
END
$$;

-- 1) Users
CREATE TABLE IF NOT EXISTS users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    avatar_url VARCHAR(1000),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2) Wallets
CREATE TABLE IF NOT EXISTS wallets (
    wallet_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE,
    balance NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
    currency VARCHAR(10) NOT NULL DEFAULT 'VND',
    status wallet_status NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT fk_wallet_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- 3) Transactions
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id VARCHAR(50) PRIMARY KEY,
    sender_id UUID NOT NULL,
    receiver_id UUID,
    amount NUMERIC(18,2) NOT NULL CHECK (amount > 0),
    message NVARCHAR(500),
    face_texture_url VARCHAR(1500),
    design_json JSONB,
    status transaction_status NOT NULL DEFAULT 'ESCROW',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expired_at TIMESTAMPTZ,
    CONSTRAINT fk_tx_sender
        FOREIGN KEY (sender_id) REFERENCES users(user_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_tx_receiver
        FOREIGN KEY (receiver_id) REFERENCES users(user_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

-- 4) DeepLinks
CREATE TABLE IF NOT EXISTS deep_links (
    link_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id VARCHAR(50) NOT NULL,
    short_code VARCHAR(100) NOT NULL UNIQUE,
    full_url VARCHAR(2000) NOT NULL,
    qr_code_url VARCHAR(2000),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_deeplink_transaction
        FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- 5) DesignTemplates
CREATE TABLE IF NOT EXISTS design_templates (
    template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_name VARCHAR(150) NOT NULL,
    thumbnail_url VARCHAR(1500),
    asset_bundle_url VARCHAR(1500) NOT NULL
);

-- 6) Stickers
CREATE TABLE IF NOT EXISTS stickers (
    sticker_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category VARCHAR(100) NOT NULL,
    image_url VARCHAR(1500) NOT NULL,
    sprite_name VARCHAR(150) NOT NULL
);

-- 7) AuditLogs
CREATE TABLE IF NOT EXISTS audit_logs (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    action VARCHAR(100) NOT NULL,
    ip_address VARCHAR(64),
    device_info VARCHAR(255),
    "timestamp" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_audit_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

-- 8) ClaimRequests
CREATE TABLE IF NOT EXISTS claim_requests (
    claim_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id VARCHAR(50) NOT NULL,
    receiver_id UUID NOT NULL,
    amount NUMERIC(18,2) NOT NULL CHECK (amount > 0),
    claimed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    proof TEXT,
    CONSTRAINT fk_claim_transaction
        FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_claim_receiver
        FOREIGN KEY (receiver_id) REFERENCES users(user_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- 9) Notifications
CREATE TABLE IF NOT EXISTS notifications (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    transaction_id VARCHAR(50),
    title NVARCHAR(255) NOT NULL,
    content NVARCHAR(2000) NOT NULL,
    type notification_type NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_notification_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_notification_transaction
        FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

-- Indexes for common query paths
CREATE INDEX IF NOT EXISTS idx_transactions_sender_id ON transactions(sender_id);
CREATE INDEX IF NOT EXISTS idx_transactions_receiver_id ON transactions(receiver_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_expired_at ON transactions(expired_at);

CREATE INDEX IF NOT EXISTS idx_deep_links_transaction_id ON deep_links(transaction_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON audit_logs("timestamp");
CREATE INDEX IF NOT EXISTS idx_claim_requests_transaction_id ON claim_requests(transaction_id);
CREATE INDEX IF NOT EXISTS idx_claim_requests_receiver_id ON claim_requests(receiver_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id_is_read_created_at ON notifications(user_id, is_read, created_at DESC);

-- Optional business-rule guard: a transaction should be claimed only once.
CREATE UNIQUE INDEX IF NOT EXISTS uq_claim_requests_transaction_id ON claim_requests(transaction_id);

CREATE TABLE IF NOT EXISTS auth_refresh_tokens (
    token_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    replaced_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_auth_refresh_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_auth_refresh_replaced_by
        FOREIGN KEY (replaced_by) REFERENCES auth_refresh_tokens(token_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_auth_refresh_user_id ON auth_refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_auth_refresh_expires_at ON auth_refresh_tokens(expires_at);
