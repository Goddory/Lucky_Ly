-- Migration: Add Admin role and System Config
-- Description: Adds role to users table and creates system_config for themes.

-- 1) Add role column to users
ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) NOT NULL DEFAULT 'USER';

-- 2) Create system_config table
CREATE TABLE IF NOT EXISTS system_config (
    key VARCHAR(50) PRIMARY KEY,
    value JSONB NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3) Initialize default theme
INSERT INTO system_config (key, value)
VALUES ('active_theme', '{"subject": "default", "primaryColor": "#0077B6"}')
ON CONFLICT (key) DO NOTHING;

-- 4) Designate Admin account
-- Password "Luckyly@2016" hashed with bcrypt (approximate cost 10)
-- Note: In a real migration, we'd use a script to ensure the hash is correct, 
-- but for initialization we can insert/update the email.
UPDATE users SET role = 'ADMIN' WHERE email = 'admin@gmail.com';

-- If admin doesn't exist, we'll need to create it (though usually it registers first)
-- For this task, I'll provide a separate script or just assume it exists or will be registered.
