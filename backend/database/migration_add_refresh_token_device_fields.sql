-- Add per-device session metadata to refresh token storage.
-- Run this after add_auth_refresh_tokens.sql on existing databases.

ALTER TABLE auth_refresh_tokens
  ADD COLUMN IF NOT EXISTS device_id VARCHAR(255),
  ADD COLUMN IF NOT EXISTS device_name VARCHAR(255),
  ADD COLUMN IF NOT EXISTS platform VARCHAR(50),
  ADD COLUMN IF NOT EXISTS user_agent TEXT,
  ADD COLUMN IF NOT EXISTS ip_address TEXT,
  ADD COLUMN IF NOT EXISTS last_used_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_auth_refresh_last_used_at ON auth_refresh_tokens(last_used_at);
