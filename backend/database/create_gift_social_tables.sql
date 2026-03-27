-- Thêm cột is_searchable vào bảng users (nếu chưa có) cho phép người dùng ẩn mình
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='is_searchable') THEN
        ALTER TABLE users ADD COLUMN is_searchable BOOLEAN DEFAULT TRUE;
    END IF;
END $$;

-- 1. Bảng lưu trữ Mối quan hệ Bạn bè (Friends)
CREATE TABLE IF NOT EXISTS friends (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    friend_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'accepted', 'declined'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_friendship UNIQUE (user_id, friend_id)
);

-- 2. Bảng lưu trữ Quà Tặng (Gifts)
CREATE TABLE IF NOT EXISTS gifts (
    id SERIAL PRIMARY KEY,
    sender_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    item_type VARCHAR(50) NOT NULL, -- loại quà (ví dụ: 'coin', 'ticket', 'item_id')
    amount INTEGER DEFAULT 1,
    max_receivers INTEGER DEFAULT 1, -- số người tối đa có thể nhận quà qua 1 link/QR
    current_receivers INTEGER DEFAULT 0,
    qr_token VARCHAR(255) UNIQUE,
    deep_link VARCHAR(500),
    is_cancelled BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Bảng phân bổ người nhận quà (Gift Receivers) 
-- dùng để track xem ai đã nhận quà này rồi (hỗ trợ max_receivers > 1)
CREATE TABLE IF NOT EXISTS gift_receivers (
    id SERIAL PRIMARY KEY,
    gift_id INTEGER NOT NULL REFERENCES gifts(id) ON DELETE CASCADE,
    receiver_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    received_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_gift_receiver UNIQUE (gift_id, receiver_id)
);

-- 4. Bảng lưu trữ Phòng Chat (Chat Rooms)
CREATE TABLE IF NOT EXISTS chat_rooms (
    id SERIAL PRIMARY KEY,
    room_type VARCHAR(20) DEFAULT 'private', -- 'private', 'group'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Bảng liên kết Người dùng và Phòng Chat (Chat Room Participants)
CREATE TABLE IF NOT EXISTS chat_room_participants (
    id SERIAL PRIMARY KEY,
    room_id INTEGER NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_room_participant UNIQUE (room_id, user_id)
);

-- 6. Bảng lưu trữ Tin nhắn (Chat Messages)
CREATE TABLE IF NOT EXISTS chat_messages (
    id SERIAL PRIMARY KEY,
    room_id INTEGER NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
    sender_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT,
    message_type VARCHAR(20) DEFAULT 'text', -- 'text', 'gift'
    gift_id INTEGER REFERENCES gifts(id) ON DELETE SET NULL, -- nếu tin nhắn chứa quà, trỏ tới bảng gifts
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Cập nhật Function/Trigger cập nhật updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger cập nhật updated_at cho bảng friends
DROP TRIGGER IF EXISTS update_friends_updated_at ON friends;
CREATE TRIGGER update_friends_updated_at
    BEFORE UPDATE ON friends
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger cập nhật updated_at cho bảng chat_rooms
DROP TRIGGER IF EXISTS update_chat_rooms_updated_at ON chat_rooms;
CREATE TRIGGER update_chat_rooms_updated_at
    BEFORE UPDATE ON chat_rooms
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
