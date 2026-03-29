-- Payment Migration: Add missing columns to transactions table
-- Run this on Neon SQL Editor

-- 1) Add order_id column (for MoMo, VNPay, ZaloPay order tracking)
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS order_id VARCHAR(100) UNIQUE;

-- 2) Add provider column (momo, vnpay, zalopay)
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS provider VARCHAR(50);

-- 3) Add return_url for ZaloPay redirect
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS return_url TEXT;

-- 4) Add updated_at for tracking status changes
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
