# Database Schema & ERD Dự án Lucky_Ly (Quà tặng ảo)

Sơ đồ ERD (Entity-Relationship Diagram) dưới đây mô tả cấu trúc liên kết dữ liệu giữa 6 Role trong hệ thống Quà tặng ảo.

## 📊 Sơ đồ Thực Thể Liên Kết (ERD)

```mermaid
erDiagram
    USERS {
        int id PK
        string role "Customer, Admin, Moderator"
        string full_name
        string student_id "Null if not student"
        decimal wallet_balance
        boolean is_banned
    }

    STORES {
        int id PK
        int owner_id FK
        string store_name
        decimal revenue
    }

    ITEMS {
        int id PK
        int store_id FK
        string item_name
        decimal price
        string item_type "Gift, Badge, Effect"
    }

    TRANSACTIONS {
        int id PK
        int sender_id FK "Buyer"
        int receiver_id FK
        int item_id FK
        decimal amount
        string status
        datetime created_at
    }

    GIFT_MESSAGES {
        int id PK
        int transaction_id FK
        string message_text
        string ai_flag "Clean, Spam, Hate_Speech"
    }

    REPORTS {
        int id PK
        int message_id FK
        int reporter_id FK
        string reason
        string status "Pending, Resolved"
    }

    MINIGAMES {
        int id PK
        string game_name "Lucky Wheel, Gacha"
        decimal cost_per_play
    }

    DROP_RATES {
        int id PK
        int game_id FK
        int item_id FK
        float probability_weight
    }

    GACHA_LOGS {
        int id PK
        int user_id FK
        int game_id FK
        int won_item_id FK "Null if lose"
        datetime played_at
    }

    PROMOTIONS {
        int id PK
        string target_audience "All, Student"
        string discount_type "Percent, Fixed"
        decimal discount_value
    }

    VOUCHERS {
        int id PK
        int promotion_id FK
        string code
        int max_uses
    }

    PROMOTION_USAGE {
        int id PK
        int voucher_id FK
        int user_id FK
        int transaction_id FK
    }

    SYSTEM_LOGS {
        int id PK
        string action_type "Topup, Withdraw, Ban"
        int target_id
        decimal amount
    }

    %% Relationships
    USERS ||--o{ STORES : "owns"
    USERS ||--o{ TRANSACTIONS : "sends/receives"
    STORES ||--o{ ITEMS : "sells"
    ITEMS ||--o{ TRANSACTIONS : "contained_in"
    TRANSACTIONS ||--|| GIFT_MESSAGES : "has_message"
    GIFT_MESSAGES ||--o{ REPORTS : "reported_for"
    USERS ||--o{ REPORTS : "files_report"
    
    MINIGAMES ||--o{ DROP_RATES : "configures"
    ITEMS ||--o{ DROP_RATES : "rewarded_in"
    USERS ||--o{ GACHA_LOGS : "plays"
    MINIGAMES ||--o{ GACHA_LOGS : "records"
    
    PROMOTIONS ||--o{ VOUCHERS : "generates"
    VOUCHERS ||--o{ PROMOTION_USAGE : "used_by"
    USERS ||--o{ PROMOTION_USAGE : "redeems"
    TRANSACTIONS ||--o| PROMOTION_USAGE : "applied_to"
```

## 🗃️ Cấu trúc bảng (Tables) theo từng Role

Dựa trên sơ đồ trên, đây là phân chia Database Tables cho từng bạn:

### 1. Nhóm Khách hàng (Customer)
- **`USERS`**: Lưu thông tin người dùng, số dư ví ($).
- **`TRANSACTIONS`**: Lưu lịch sử mua quà, tặng quà, liên kết ai tặng cho ai (`sender_id` tặng `receiver_id`).

### 2. Nhóm Cửa hàng (Store)
- **`STORES`**: Hồ sơ gian hàng.
- **`ITEMS`**: Danh sách quà tặng ảo cửa hàng đã tạo (màu sắc, mô tả, giá cả, thẻ tag). Tiền doanh thu sẽ đổ về gian hàng qua dữ liệu từ bảng mua bán.

### 3. Nhóm Quản trị viên (Admin)
- **`SYSTEM_LOGS`**: Lưu toàn bộ log nạp tiền vào ví, yêu cầu rút tiền từ ví ra tài khoản ngân hàng của Cửa hàng, và các action quản trị ban/mở khóa tài khoản.

### 4. Nhóm Quản lý Sự kiện / Minigame
- **`MINIGAMES`**: Danh sách sự kiện (Gacha hộp quà, Vòng quay).
- **`DROP_RATES`**: Tỷ lệ rớt đồ thuật toán sử dụng (Probability weight) cho từng món quà được cấu hình.
- **`GACHA_LOGS`**: Lịch sử tiêu ví chơi Gacha của user.

### 5. Nhóm CSKH / Kiểm duyệt (Moderator)
- **`GIFT_MESSAGES`**: Text lời chúc đính kèm trong hộp quà. Đã qua AI dán nhãn phân loại (`Clean`, `Spam`, `Hate_Speech`).
- **`REPORTS`**: Đơn tố cáo (Report) từ người dùng nếu ai đó cố tình tặng kèm quà xúc phạm hoặc lừa đảo.

### 6. Nhóm Quản lý Marketing / Khuyến mãi
- **`PROMOTIONS` & `VOUCHERS`**: Tạo chiến dịch và phát mã Code giảm giá. Set đối tượng cụ thể (Ví dụ hệ thống kiểm tra `student_id` có tồn tại thì mới cho dùng code).
- **`PROMOTION_USAGE`**: Theo dõi tiến độ hóa đơn nào đã sử dụng mã voucher nào, để tính ROI(lợi nhuận/chi phí) cho độ tuổi sinh viên.

---

> 🎉 Hoàn toàn dựa trên Schema này, nhóm có thể viết script Python (`Faker`, `SQLAlchemy`) tạo dữ liệu giả lập cho ứng dụng đủ 6 nghiệp vụ!
