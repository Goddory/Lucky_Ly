-- Add fcm_token column to users table for push notifications
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='fcm_token') THEN
        ALTER TABLE users ADD COLUMN fcm_token TEXT;
    END IF;
END $$;
