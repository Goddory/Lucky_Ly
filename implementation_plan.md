# Kế hoạch Tích hợp Avaturn, Unity & Hạ tầng CSDL Phân Tán

## Mục tiêu (Goal Description)
1. **Avaturn & Unity:** Tích hợp hệ thống Avaturn qua WebView để người dùng tạo avatar 3D. Tải mô hình 3D (`.glb`) và khởi tạo Project Unity độc lập được nhúng thẳng vào Flutter (qua `flutter_unity_widget`) để render 3D lên màn hình "Tôi".
2. **Hạ tầng CSDL Phân tán (Distributed DB Infrastructure):**
   - **Neon (PostgreSQL):** Đã có sẵn, dùng cho dữ liệu cốt lõi như User Auth, giao dịch. Đóng vai trò Data of Truth cho định danh phân tán.
   - **MongoDB Cloud (NoSQL):** Chứa các `JSON Document` lưu cấu hình render, chỉ số 3D, sự kiện thao tác offline. Hoạt động song song cùng Neon ở Layer Backend.
   - **SQLite (Local Storage trên Mobile - Full Mirror):** Đóng vai trò bản sao cục bộ của toàn bộ Cloud DB (gồm User Profile, Designs, Cấu hình Avatar). Ứng dụng sẽ ưu tiên đọc ghi từ SQLite (Offline-First) để luôn hoạt động ngay cả khi không có mạng.
3. **Cơ chế Đồng bộ 2 Chiều (Two-way Sync) Toàn diện:**
   - Ứng dụng đọc/ghi trực tiếp vào SQLite cục bộ (0 độ trễ, 100% offline).
   - Khi có thao tác Ghi, bản ghi trong SQLite được đánh cờ `is_sync=false` (Dirty state).
   - Hệ thống tự động đẩy (Push) các bản ghi dirty lên Cloud khi có mạng, và kéo (Pull) dữ liệu mới từ Cloud về ghi đè SQLite, thông qua màn hình Giao diện tắt/bật đồng bộ.

## User Review Required & Socratic Gate
> [!NOTE]
> Tất cả các yêu cầu từ bạn đã được làm rõ thông qua Socratic Gate. Kế hoạch đã hoàn thiện và sẵn sàng để Triển khai (EXECUTION). Bạn hãy gõ "Đồng ý" hoặc "Proceed" để mình tiến hành Cấu hình Backend và Database nhé.

## Kiến trúc Đề xuất (Proposed Architecture)

### Luồng Hoạt Động CSDL và Avaturn
```mermaid
sequenceDiagram
    participant User
    participant Flutter (SQLite)
    participant Backend (Mongo/Neon)
    participant WebView (Avaturn)
    participant Unity Widget

    User->>Flutter (SQLite): Bấm tạo Avatar
    Flutter (SQLite)->>WebView (Avaturn): Mở WebView
    WebView (Avaturn)-->>Flutter (SQLite): Trả URL v2.avatar.exported (.glb)
    Flutter (SQLite)->>Flutter (SQLite): Lưu URL và Tải .glb về máy, gán flag is_sync=false
    Flutter (SQLite)->>Backend (Mongo/Neon): Gửi URL lưu vào Mongo (Nếu bật Cấu hình Tự động Sync)
    User->>Flutter (SQLite): Bấm "Đồng bộ thủ công"
    Flutter (SQLite)<->Backend (Mongo/Neon): Push/Pull dữ liệu 2 chiều.
    Flutter (SQLite)-->>Unity Widget: Đẩy Local File Path sang Unity để Render Offline
```

### Các thành phần chính

#### 1. Setup Backend (Mongo + Neon)
- **[MODIFY] [backend/package.json](file:///c:/Users/super/source/repos/Lucky_Ly/backend/package.json) & [.env](file:///c:/Users/super/source/repos/Lucky_Ly/backend/.env)**: Thêm `mongoose`. Cấu hình biến môi trường kết nối.
- **[NEW] `backend/controllers/sync.controller.js`**: Viết REST endpoint `/api/sync/pull` và `/api/sync/push` xử lý Request từ App Mobile ghép nối dữ liệu Mongo.

#### 2. Mobile Strategy (SQLite Full Offline-First)
- **[MODIFY] [pubspec.yaml](file:///c:/Users/super/source/repos/Lucky_Ly/backend/lucky_ly_mobile/pubspec.yaml)**: Thêm `sqflite`, `path_provider` (đã làm).
- **[MODIFY] Lớp [SyncManager](file:///c:/Users/super/source/repos/Lucky_Ly/backend/lucky_ly_mobile/lib/core/services/sync_manager.dart#6-110) & [DatabaseHelper](file:///c:/Users/super/source/repos/Lucky_Ly/backend/lucky_ly_mobile/lib/core/database/database_helper.dart#4-102)**:
  - Mở rộng DB Cục bộ: Thay vì chỉ có bảng [Avatars](file:///c:/Users/super/source/repos/Lucky_Ly/backend/lucky_ly_mobile/lib/core/database/database_helper.dart#74-83), sẽ khởi tạo toàn bộ CSDL thu nhỏ gồm:
    - Bảng `Users` (Mirror từ Neon, lưu Name, Email, Token, Settings).
    - Bảng `Designs/Posts` (Mirror từ Mongo hoặc Neon).
    - Bảng [Avatars](file:///c:/Users/super/source/repos/Lucky_Ly/backend/lucky_ly_mobile/lib/core/database/database_helper.dart#74-83) (Mirror từ Mongo, kèm `localPath`).
  - Tất cả các bảng đều có cột `is_sync (INT)` và `client_updated_at (TEXT)`.
  - Hàm [pushData()](file:///c:/Users/super/source/repos/Lucky_Ly/backend/lucky_ly_mobile/lib/core/services/sync_manager.dart#9-51) sẽ quét tất cả các bảng tìm `is_sync=0` và đẩy theo từng luồng API.
  - Hàm [pullData()](file:///c:/Users/super/source/repos/Lucky_Ly/backend/lucky_ly_mobile/lib/core/services/sync_manager.dart#52-102) sẽ đồng bộ chéo từ Server về tất cả các bảng.
- **[MODIFY] Repository Pattern (UI <-> DB)**: Chỉnh sửa toàn bộ các hàm gọi API trong ứng dụng (giả sử ProfileScreen, Home) chuyển sang đọc từ [DatabaseHelper](file:///c:/Users/super/source/repos/Lucky_Ly/backend/lucky_ly_mobile/lib/core/database/database_helper.dart#4-102) cục bộ thay vì gọi trực tiếp `http.get`.

#### 3. Tích hợp Avaturn & Unity (Frontend)
- **[NEW] `avaturn_webview_screen.dart`**: Trích xuất link models từ Event Data Avaturn.
- **[NEW] `lucky_ly_unity` (Project Unity)**: Tạo scene với Plugin `glTFast` / `TriLib` dùng C# tải model `.glb`.
- **[MODIFY] [profile_screen.dart](file:///c:/Users/super/source/repos/Lucky_Ly/backend/lucky_ly_mobile/lib/profile_screen.dart)**: Gắn `UnityWidget`. Quét dữ liệu SQLite cục bộ để render. Load ngay tắp lự ngay cả khi offline (vì model đã tải về).

## Kế hoạch Kiểm tra (Verification Plan)
- Đảm bảo Backend kết nối được song song Neon (PG) và Mongo.
- Giả lập mất mạng trên máy ảo: Đổi avatar, xem avatar 3D trong Unity offline có thay dổi trạng thái không.
- Bật mạng lên và bấm nút "Đồng bộ", kiểm tra phía server MongoDB đã nhận được dữ liệu hay chưa.
