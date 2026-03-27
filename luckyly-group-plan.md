# Lên kế hoạch nhóm môn học: Dự án Lucky_Ly (Quà tặng ảo)

**Thông tin chung:**
- **Dự án:** Lucky_Ly (Nền tảng quà tặng ảo / Virtual Gifts)
- **Số lượng thành viên:** 6 người
- **Thời lượng:** 3 ngày (Gấp)
- **Yêu cầu mỗi cá nhân:** 
  1. Xây dựng 1 UI theo Role cụ thể.
  2. 3 Bộ datasets thu thập + 1 Bộ dataset tự build.
  3. Source code thao tác với DB + Áp dụng 1 Thuật toán riêng biệt.

---

## 👥 Phân chia công việc chi tiết

### Thành viên 1: Khách hàng (Người dùng cuối / Tặng - Nhận quà)
*Người dùng tương tác chính với hệ thống: Mua quà, tặng quà ảo, xem lịch sử giao dịch.*

- **UI Role:** Khách hàng (Customer App)
  - Màn hình Home (Danh mục quà ảo).
  - Chi tiết quà tặng & Màn hình thanh toán/tặng quà.
  - Lịch sử giao dịch (Nhận/Tặng).
- **Datasets:**
  1. *E-commerce User Behavior* (Lịch sử thao tác/mua sắm).
  2. *Virtual Items Catalog* (Thông tin các món đồ ảo, giá tiền).
  3. *User Profile & Social Network* (Dữ liệu bạn bè, độ tương tác).
  - **Tự build:** `luckyly_transactions.csv` (Lịch sử AI sinh ra về việc ai tặng quà gì cho ai trong Lucky_Ly).
- **Thuật toán áp dụng:**
  - **Hệ gợi ý (Recommendation System) - Content-Based hoặc Collaborative Filtering:** Gợi ý quà tặng ảo dựa trên lịch sử tặng quà trước đây hoặc sở thích của người bạn đang muốn tặng.

---

### Thành viên 2: Cửa hàng / Creator (Người tạo & bán quà ảo)
*Bên thứ 3 tham gia đăng tải hình ảnh quà ảo, hiệu ứng, và theo dõi doanh thu.*

- **UI Role:** Cửa hàng / Đối tác (Store/Creator Dashboard)
  - Màn hình đăng sản phẩm (Upload hình ảnh quà, set giá).
  - Dashboard thống kê lượt mua, doanh thu.
  - Quản lý kho quà tặng đã tạo.
- **Datasets:**
  1. *Retail Sales Dataset* (Dữ liệu doanh số bán hàng theo thời gian).
  2. *Product Pricing/Reviews dataset* (Đánh giá và giá cả sản phẩm).
  3. *E-commerce Store Inventory* (Dữ liệu kho hàng ảo).
  - **Tự build:** `luckyly_store_inventory.csv` (Các loại quà tặng ảo do cửa hàng tạo ra, số lượng bán ra, doanh thu).
- **Thuật toán áp dụng:**
  - **Luật kết hợp (Association Rules như Apriori / FP-Growth):** Gợi ý bán chéo (Cross-sell). VD: Người mua "Bánh kem ảo" thường sẽ mua kèm "Pháo hoa chúc mừng ảo". Cửa hàng có thể tạo Bundle nhờ thuật toán này.

---

### Thành viên 3: Admin (Hệ thống tổng)
*Kiểm soát toàn bộ ứng dụng, dòng tiền, nạp/rút và theo dõi hoạt động.*

- **UI Role:** Quản trị viên (Admin Dashboard)
  - Overview Dashboard (Biểu đồ tổng doanh thu, user active).
  - Quản lý người dùng (Block/Unblock).
  - Duyệt yêu cầu rút tiền của Cửa hàng.
- **Datasets:**
  1. *Financial Fraud Detection Dataset* (Dữ liệu giao dịch thẻ tín dụng/nạp tiền).
  2. *System Logs / Server Metrics* (Log hệ thống).
  3. *User Session / Analytics* (Thời gian online của user).
  - **Tự build:** `luckyly_admin_logs.csv` (Biến động số dư ví của toàn hệ thống, log nạp/rút tiền).
- **Thuật toán áp dụng:**
  - **Phát hiện bất thường (Anomaly Detection - VD: Isolation Forest / K-Means):** Phát hiện các giao dịch nạp tiền hoặc tặng quà số lượng lớn/đáng ngờ để cảnh báo gian lận rửa tiền hoặc hack tài khoản.

---

### Thành viên 4: Quản lý Game / Sự kiện (Minigame Manager)
*Lucky_Ly có thể tích hợp mini-game (Vòng quay may mắn, Gacha) để user tiêu coin trúng quà ảo.*

- **UI Role:** Quản lý Sự kiện (Event/Minigame Manager)
  - Giao diện setup Vòng quay may mắn (Lucky Wheel).
  - Cấu hình tỷ lệ rớt quà (Drop Rate) cho từng món.
  - Thống kê top người chơi trúng thưởng.
- **Datasets:**
  1. *Gaming Player Retention/Log dataset* (Lịch sử chơi game, tỷ lệ nạp).
  2. *Gacha Drop Rates Logs* (Lịch sử rớt đồ từ hộp quà).
  3. *A/B Testing game mechanics dataset*.
  - **Tự build:** `luckyly_gacha_logs.csv` (Lịch sử quay thưởng của user, kết quả thắng thua, số coin đã tiêu).
- **Thuật toán áp dụng:**
  - **Thuật toán ngẫu nhiên có trọng số (Weighted Random Algorithm / PRNG):** Code logic quay Gacha/Vòng quay sao cho quà xịn có (Weight) thấp, quà thường có (Weight) cao. Hoặc dùng *Linear Regression* để dự đoán doanh thu sự kiện dựa trên drop rate.

---

### Thành viên 5: Nhân viên CSKH & Kiểm duyệt (Moderator)
*Giữ cho môi trường tặng quà trong sạch, không spam, không chửi bậy trong lời nhắn.*

- **UI Role:** Kiểm duyệt viên (Moderator/Support)
  - Màn hình quản lý các Report (báo cáo vi phạm) từ người dùng.
  - Xem và quản lý các Feedback/Support Tickets.
  - Dashboard AI duyệt comment (Tự động flag các comment xấu).
- **Datasets:**
  1. *Spam & Hate Speech Text Dataset* (Dữ liệu text chửi thề, spam lừa đảo).
  2. *Customer Support Tickets* (Dữ liệu chat hỗ trợ khách hàng).
  3. *App Reviews Sentiment Analysis dataset*.
  - **Tự build:** `luckyly_gift_messages.csv` (Các đoạn tin nhắn chúc mừng đính kèm khi tặng quà chứa từ khóa bình thường và từ khóa vi phạm).
- **Thuật toán áp dụng:**
  - **Phân loại văn bản học máy (Text Classification - NLP VD: Naive Bayes, SVM):** Tự động phân tích và dán nhãn Message đính kèm quà tặng là Bình thường (Clean) hay Vi phạm (Hate speech/Spam) trước khi gửi đến người nhận.

---

### Thành viên 6: Quản lý Marketing / Khuyến mãi (Đặc biệt cho Sinh viên/Học sinh)
*Hệ thống Lucky_Ly hướng đến giới trẻ, đặc biệt là học sinh sinh viên, cần có riêng người phụ trách luồng nghiệp vụ này.*

- **UI Role:** Quản lý Chiến dịch (Promotion/Marketing Manager)
  - Màn hình tạo Voucher giảm giá / Flash sale giờ vàng mua đồ ảo.
  - Xét duyệt và cấp tag "Học sinh/Sinh viên" (Ví dụ form tải lên thẻ sinh viên để nhận Discount).
  - Dashboard theo dõi hiệu quả sử dụng voucher theo độ tuổi khách hàng.
- **Datasets:**
  1. *Marketing Campaign & Coupon Usage Dataset* (Lịch sử phân phối và sử dụng mã giảm giá).
  2. *Student / Youth Demographics & E-commerce Spending* (Hành vi mua sắm trực tuyến của giới trẻ).
  3. *Customer Churn Dataset* (Dữ liệu tần suất người dùng bỏ app).
  - **Tự build:** `luckyly_promotions.csv` (Lịch sử phát voucher tự động cho các nhóm tài khoản Học sinh/Sinh viên).
- **Thuật toán áp dụng:**
  - **Phân cụm khách hàng (Clustering model - K-Means) HOẶC Dự đoán rời bỏ (Churn Prediction - Random Forest / XGBoost):** 
    - Phân cụm: Máy học gom nhóm khách hàng theo độ tuổi và thói quen mua/giơ tài chính thấp. Từ đó UI tự động hiển thị/tự động tung ra các phần quà, combo giá sinh viên.
    - Churn Prediction: Truy vết và phát hiện tài khoản học sinh đã lâu không mở app hoặc cạn tiền, hệ thống tự động châm thêm mã `WELCOME_BACK` để lấy lại tương tác.

---

## 🎯 Kế hoạch thực hiện trong 3 ngày

- **Ngày 1: Data & DB**
  - Chốt Schema Database chung.
  - Crawl/Tải 15 datasets từ [Kaggle](https://www.kaggle.com), [UCI Machine Learning Repository](https://archive.ics.uci.edu).
  - Viết Python script sinh ra 5 bộ file CSV tự build (Dùng thư viện `Faker`).
  - Import tất cả vào Database hệ thống.
  
- **Ngày 2: Algorithms & API**
  - Bắt tay code Thuật toán riêng của từng người bằng Python/NodeJS.
  - Đóng gói thuật toán thành API.
  - Lấy API cắm vào DB để test Output.

- **Ngày 3: UI & Tích hợp (Tăng tốc)**
  - Dựng UI/Giao diện theo đúng Role (Không cần làm Full app, chỉ làm đúng các Màn hình của Role mình).
  - Gọi API thuật toán hiển thị lên UI.
  - Ráp nối dữ liệu, nạp báo cáo thuyết trình.
