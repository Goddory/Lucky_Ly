-- Migration: Create gifts table for virtual gift feature
CREATE TABLE IF NOT EXISTS gifts (
    id SERIAL PRIMARY KEY,
    sender_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    receiver_email VARCHAR(255) NOT NULL,
    theme VARCHAR(20) NOT NULL CHECK (theme IN ('tet', 'valentine')),
    model_id VARCHAR(100) NOT NULL,
    stickers JSONB DEFAULT '[]',
    message TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'opened')),
    opened_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_gifts_receiver ON gifts(receiver_email, status);
CREATE INDEX idx_gifts_sender ON gifts(sender_id);
