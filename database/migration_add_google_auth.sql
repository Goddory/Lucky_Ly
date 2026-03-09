-- Migration: Add Google Sign-In support
-- Run this AFTER init_lucky_ly_postgres.sql

-- Allow social login users without password
ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;

-- Track authentication provider (local = email/password, google = Google Sign-In)
ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(20) NOT NULL DEFAULT 'local';
ALTER TABLE users ADD COLUMN IF NOT EXISTS provider_uid VARCHAR(255);

-- Index for fast lookup by provider
CREATE INDEX IF NOT EXISTS idx_users_provider ON users(auth_provider, provider_uid);
