-- Migration: Add social login support to existing database
-- Run this on an existing database that was created with init_lucky_ly_postgres.sql

-- Add social login columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS facebook_id VARCHAR(255) UNIQUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(20) NOT NULL DEFAULT 'local';
ALTER TABLE users ADD COLUMN IF NOT EXISTS provider_uid VARCHAR(255);

-- Allow password_hash to be NULL for social login users (Facebook/Google)
ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;

-- Allow email to be NULL for Facebook users without email
ALTER TABLE users ALTER COLUMN email DROP NOT NULL;
