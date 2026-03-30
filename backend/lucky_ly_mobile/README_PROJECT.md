# Lucky Ly Mobile - README Rieng

## 1. Thong tin co ban
- Ten project: lucky_ly_mobile
- Vi tri: backend/lucky_ly_mobile
- Nen tang: Flutter + Dart
- Muc tieu: ung dung Lucky Ly cho auth, social, chat, gifts, payment, store va admin.

## 2. Cong nghe chinh
- State management: Provider
- API: http package
- Local storage: SharedPreferences, FlutterSecureStorage, SQLite (sqflite)
- Realtime: socket_io_client
- Social login: Google Sign-In, Facebook Auth

## 3. Chay project
1. Cai dependencies: flutter pub get
2. Chay web debug: flutter run -d web-server --dart-define=API_BASE_URL=http://localhost:4000
3. Chay Android emulator: flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000

## 4. Cau truc thu muc chinh
- lib/main.dart: bootstrap app, auth flow, social login, deep-link, provider wiring.
- lib/core: model, service, database, sync.
- lib/providers: trang thai app theo domain.
- lib/screens: man hinh theo tung module nghiep vu.
- lib/widgets: widget tai su dung va hieu ung.

## 5. Tac dung cua cac file Dart trong lib
- lib\app_theme.dart: UI/logic theo module tuong ung.
- lib\celebrate_screen.dart: UI/logic theo module tuong ung.
- lib\core\database\database_helper.dart: UI/logic theo module tuong ung.
- lib\core\models\event_model.dart: UI/logic theo module tuong ung.
- lib\core\services\api_client.dart: UI/logic theo module tuong ung.
- lib\core\services\calendar_api_service.dart: UI/logic theo module tuong ung.
- lib\core\services\database_helper.dart: UI/logic theo module tuong ung.
- lib\core\services\socket_service.dart: Quan ly websocket, room, message, notification, typing.
- lib\core\services\sync_manager.dart: Dong bo du lieu offline-local voi backend.
- lib\data\gift_catalog.dart: UI/logic theo module tuong ung.
- lib\design_selection_screen.dart: UI/logic theo module tuong ung.
- lib\gift_center_screen.dart: UI/logic theo module tuong ung.
- lib\history_screen.dart: UI/logic theo module tuong ung.
- lib\home_screen.dart: Man hinh tong quan sau dang nhap, dieu huong tac vu chinh.
- lib\main.dart: UI/logic theo module tuong ung.
- lib\mobile_studio_screen.dart: UI/logic theo module tuong ung.
- lib\money_transfer_screen.dart: UI/logic theo module tuong ung.
- lib\offers_screen.dart: UI/logic theo module tuong ung.
- lib\payment_screen.dart: Man hinh thanh toan va flow MoMo/VNPay/ZaloPay.
- lib\profile_screen.dart: UI/logic theo module tuong ung.
- lib\providers\auth_provider.dart: UI/logic theo module tuong ung.
- lib\providers\chat_provider.dart: UI/logic theo module tuong ung.
- lib\providers\friend_provider.dart: UI/logic theo module tuong ung.
- lib\providers\store_provider.dart: UI/logic theo module tuong ung.
- lib\providers\theme_provider.dart: UI/logic theo module tuong ung.
- lib\screens\admin\admin_dashboard_screen.dart: UI/logic theo module tuong ung.
- lib\screens\admin\customer_segments_screen.dart: UI/logic theo module tuong ung.
- lib\screens\admin\flash_sale_screen.dart: UI/logic theo module tuong ung.
- lib\screens\admin\loyalty_membership_screen.dart: UI/logic theo module tuong ung.
- lib\screens\admin\marketing_dashboard_screen.dart: UI/logic theo module tuong ung.
- lib\screens\admin\push_campaign_screen.dart: UI/logic theo module tuong ung.
- lib\screens\admin\statistics_screen.dart: UI/logic theo module tuong ung.
- lib\screens\admin\student_verification_screen.dart: UI/logic theo module tuong ung.
- lib\screens\admin\theme_management_screen.dart: UI/logic theo module tuong ung.
- lib\screens\admin\users_management_screen.dart: UI/logic theo module tuong ung.
- lib\screens\admin\voucher_management_screen.dart: UI/logic theo module tuong ung.
- lib\screens\avatar_3d_screen.dart: UI/logic theo module tuong ung.
- lib\screens\avaturn_screen.dart: UI/logic theo module tuong ung.
- lib\screens\chat\chat_list_screen.dart: UI/logic theo module tuong ung.
- lib\screens\chat\chat_room_screen.dart: UI/logic theo module tuong ung.
- lib\screens\gifts\gift_notification_screen.dart: UI/logic theo module tuong ung.
- lib\screens\gifts\gift_open_screen.dart: UI/logic theo module tuong ung.
- lib\screens\gifts\gift_preview_screen.dart: UI/logic theo module tuong ung.
- lib\screens\gifts\gift_qr_screen.dart: UI/logic theo module tuong ung.
- lib\screens\gifts\themed_gift_builder_screen.dart: UI/logic theo module tuong ung.
- lib\screens\social\friend_management_screen.dart: UI/logic theo module tuong ung.
- lib\screens\store\combo_suggestion_screen.dart: UI/logic theo module tuong ung.
- lib\screens\store\inventory_screen.dart: UI/logic theo module tuong ung.
- lib\screens\store\revenue_screen.dart: UI/logic theo module tuong ung.
- lib\screens\store\store_dashboard_screen.dart: UI/logic theo module tuong ung.
- lib\widgets\calendar_popup.dart: UI/logic theo module tuong ung.
- lib\widgets\confetti_painter.dart: UI/logic theo module tuong ung.
- lib\widgets\custom_loading.dart: UI/logic theo module tuong ung.
- lib\widgets\glb_model_viewer.dart: UI/logic theo module tuong ung.
- lib\widgets\particle_overlay.dart: UI/logic theo module tuong ung.
- lib\widgets\theme_particles.dart: UI/logic theo module tuong ung.

## 6. Tai lieu bo sung
- FUNCTION_COMMENTS_LIB.md: danh sach ham va comment chuc nang cua tung ham trong lib.


