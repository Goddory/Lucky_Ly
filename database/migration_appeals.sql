-- Thêm cột lý do khóa vào bảng users
ALTER TABLE users ADD COLUMN IF NOT EXISTS block_reason TEXT;

-- Tạo bảng quản lý kháng cáo
CREATE TABLE IF NOT EXISTS user_appeals (
    appeal_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    reason TEXT NOT NULL, -- Nội dung kháng cáo của người dùng
    status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, APPROVED, REJECTED
    admin_note TEXT, -- Ghi chú của admin khi phản hồi kháng cáo
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Thêm index để tìm kiếm nhanh
CREATE INDEX IF NOT EXISTS idx_user_appeals_user_id ON user_appeals(user_id);
CREATE INDEX IF NOT EXISTS idx_user_appeals_status ON user_appeals(status);
