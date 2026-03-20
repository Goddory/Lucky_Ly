# Task Checklist: Avaturn, Unity & 2-Way Sync DB

## Pha 1: Hạ Tầng CSDL Phân Tán (Database Infrastructure)
- [x] Backend: Cài đặt và cấu hình `mongoose` để kết nối MongoDB Cloud.
- [x] Backend: Viết các REST APIs `/api/sync/pull` và `/api/sync/push` cho mobile đồng bộ dữ liệu.
- [x] Mobile: Cài đặt `sqflite` và `path_provider` trong thư mục Flutter.
- [x] Mobile: Khởi tạo [DatabaseHelper](file:///c:/Users/super/source/repos/Lucky_Ly/backend/lucky_ly_mobile/lib/core/database/database_helper.dart#4-153) với bảng cache `Avatars`.
- [x] Mobile: Xây dựng service [SyncManager](file:///c:/Users/super/source/repos/Lucky_Ly/backend/lucky_ly_mobile/lib/core/services/sync_manager.dart#6-116) đảm nhiệm thuật toán đồng bộ 2 chiều (Push/Pull) nguyên mẫu.
- [x] Mobile: Mở rộng [DatabaseHelper](file:///c:/Users/super/source/repos/Lucky_Ly/backend/lucky_ly_mobile/lib/core/database/database_helper.dart#4-153) - Thêm các bảng `Users`, `Designs/Posts` với cờ `isSync`.
- [x] Mobile: Cập nhật [SyncManager](file:///c:/Users/super/source/repos/Lucky_Ly/backend/lucky_ly_mobile/lib/core/services/sync_manager.dart#6-116) để hỗ trợ Push/Pull toàn bộ các bảng trên.
- [x] Mobile: Chuyển đổi các Model/UI (như màn Profile) đọc từ [DatabaseHelper](file:///c:/Users/super/source/repos/Lucky_Ly/backend/lucky_ly_mobile/lib/core/database/database_helper.dart#4-153) thay vì API trực tiếp.

## Pha 2: Tích hợp Avaturn (Tạo Avatar)
- [x] Mobile: Cài đặt `webview_flutter`.
- [x] Mobile: Xây dựng [AvaturnScreen](file:///c:/Users/super/source/repos/Lucky_Ly/backend/lucky_ly_mobile/lib/screens/avaturn_screen.dart#9-18) để load WebView và lắng nghe Javascript events.
- [x] Mobile: Trích xuất URL `.glb` của mô hình 3D đẩy xuống DB cục bộ.

## Pha 3: Xử lý Tải File Cache Offline
- [x] Mobile: Tải file từ URL `.glb` lưu vật lý vào `getApplicationDocumentsDirectory`.
- [x] Mobile: Lưu đường dẫn path cục bộ vào SQLite.

## Pha 4: Chuẩn bị & Cấu hình Unity (Setup)
- [x] Khởi tạo 1 project Unity 3D độc lập (trong hoặc ngoài thư mục flutter).
- [x] Unity: Cài `glTFast` xử lý tải models `.glb` runtime.
- [ ] Unity: Cấu hình Export UaaL (Unity as a Library) cho Android.
- [x] Mobile: Cài đặt `flutter_unity_widget`.

## Pha 5: Triển Khai Render 3D trên UI
- [x] Unity: Viết C# script nhận message chứa đường dẫn file cục bộ.
- [x] Mobile: Tạo màn [avatar_3d_screen.dart](file:///c:/Users/super/source/repos/Lucky_Ly/backend/lucky_ly_mobile/lib/screens/avatar_3d_screen.dart) chứa `UnityWidget`.
- [x] Mobile: Tích hợp nút Xem và truyền trực tiếp đường dẫn file lưu từ thư mục vào Unity.
