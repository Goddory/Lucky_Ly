-- Student verification table for marketing admin
CREATE TABLE IF NOT EXISTS student_verifications (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    card_image_url TEXT NOT NULL,
    school_name VARCHAR(255),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    reviewed_by UUID REFERENCES users(user_id),
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sv_user_id ON student_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_sv_status ON student_verifications(status);
