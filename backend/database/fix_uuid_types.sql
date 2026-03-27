-- Tệp sửa lỗi kiểu dữ liệu UUID và khởi tạo các bảng mạng xã hội/chat còn thiếu
-- Chạy tệp này để đảm bảo toàn bộ hệ thống sử dụng UUID cho user_id

-- 1. Bảng lưu trữ Mối quan hệ Bạn bè (Friends)
CREATE TABLE IF NOT EXISTS friends (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'accepted', 'declined'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_friendship UNIQUE (user_id, friend_id)
);

-- 2. Đảm bảo bảng Quà Tặng (Gifts) sử dụng UUID cho sender_id
-- Nếu bảng đã tồn tại, chúng ta cần chuyển đổi kiểu dữ liệu
DO $$
BEGIN
    -- Kiểm tra xem cột sender_id có phải là INTEGER không
    IF (SELECT data_type FROM information_schema.columns 
        WHERE table_name = 'gifts' AND column_name = 'sender_id') = 'integer' THEN
        
        -- Xóa khóa ngoại cũ
        ALTER TABLE gifts DROP CONSTRAINT IF EXISTS gifts_sender_id_fkey;
        
        -- Chuyển đổi kiểu dữ liệu
        ALTER TABLE gifts ALTER COLUMN sender_id TYPE UUID USING sender_id::text::uuid;
        
        -- Thêm lại khóa ngoại trỏ đúng cột user_id (UUID)
        ALTER TABLE gifts ADD CONSTRAINT gifts_sender_id_fkey 
            FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE CASCADE;
            
        RAISE NOTICE 'Đã cập nhật bảng gifts sang UUID.';
    END IF;
END $$;

-- 3. Bảng phân bổ người nhận quà (Gift Receivers)
CREATE TABLE IF NOT EXISTS gift_receivers (
    id SERIAL PRIMARY KEY,
    gift_id INTEGER NOT NULL REFERENCES gifts(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    received_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_gift_receiver UNIQUE (gift_id, receiver_id)
);

-- 4. Bảng lưu trữ Phòng Chat (Chat Rooms)
CREATE TABLE IF NOT EXISTS chat_rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_type VARCHAR(20) DEFAULT 'private', -- 'private', 'group'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Bảng liên kết Người dùng và Phòng Chat (Chat Room Participants)
CREATE TABLE IF NOT EXISTS chat_room_participants (
    id SERIAL PRIMARY KEY,
    room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_room_participant UNIQUE (room_id, user_id)
);

-- 6. Bảng lưu trữ Tin nhắn (Chat Messages)
CREATE TABLE IF NOT EXISTS chat_messages (
    id SERIAL PRIMARY KEY,
    room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    content TEXT,
    message_type VARCHAR(20) DEFAULT 'text', -- 'text', 'gift'
    gift_id INTEGER REFERENCES gifts(id) ON DELETE SET NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Thêm trigger cập nhật updated_at cho các bảng mới (nếu chưa có)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_friends_updated_at') THEN
        CREATE TRIGGER update_friends_updated_at
            BEFORE UPDATE ON friends FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_chat_rooms_updated_at') THEN
        CREATE TRIGGER update_chat_rooms_updated_at
            BEFORE UPDATE ON chat_rooms FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;
