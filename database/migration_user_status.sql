-- Migration: Add status column to users
-- Description: Adds status column to manage user account states (ACTIVE, BLOCKED).

ALTER TABLE users ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE';
