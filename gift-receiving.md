# Kế hoạch triển khai: Luồng nhận quà & Tính năng Xã hội (Gift & Social Feature)

## Overview (Tổng quan)
Tính năng cho phép người dùng tặng quà cho nhau, đồng thời hỗ trợ quản lý bạn bè và nhắn tin thời gian thực (Realtime Chat). Khi tặng quà, người dùng có thể tạo QR/Deep link (tồn tại 24h, hỗ trợ gửi cho 1 hoặc nhiều người), hoặc chuyển trực tiếp qua tin nhắn. Hệ thống tích hợp đầy đủ kiểm soát quyền riêng tư, cho phép thu hồi quà và giới hạn nhắn tin đối với người lạ.

## Project Type
**MOBILE** (Sử dụng `mobile-developer` cho Flutter) và **BACKEND** (Sử dụng `backend-specialist` cho Node.js API).

## Success Criteria (Tiêu chí thành công)
1. **Luồng tặng quà:** Tạo QRCode/Deep link tặng quà (hỗ trợ nhiều người nhận), nếu sau 24h không ai nhận -> hết hạn hoàn quà. Đặc quyền thu hồi (cancel) trước khi người kia mở quà thành công.
2. **Quản lý Bạn bè:** Có mục "Bạn bè" với 3 tab: Lời mời đã gửi, Lời mời đã nhận, Danh sách bạn bè.
3. **Chat Real-time:** Hỗ trợ chat mượt mà qua Socket. Nếu chưa là bạn bè, người lạ chỉ gửi được DUY NHẤT 1 tin nhắn chứa thông báo quà tặng và không được chat tiếp. Nếu là bạn bè thì chat bình thường.
4. **Quyền riêng tư:** Tùy chọn Settings cho phép bật/tắt "Cho phép tìm kiếm qua Username". Không ai tìm ra được tài khoản nếu bật tính năng ẩn.
5. **Thông báoPush/In-app:** Gửi Push notification cho các event: Nhận quà, Có lời mời kết bạn, Có tin nhắn mới.

## Tech Stack
- **Frontend (Mobile):** Flutter, Socket.io-client, Firebase Cloud Messaging (FCM), `qr_code_scanner`, `uni_links` (Deep link).
- **Backend:** Node.js, Express, Socket.io (cho Chat), MongoDB, Firebase Admin SDK (Push Notification).

## File Structure (Cấu trúc file dự kiến backend/mobile)
- `backend/src/models/gift.model.js` (Thêm trường `expiresAt`, `isCancelled`, `maxReceivers`)
- `backend/src/models/friend.model.js` (Quản lý friend requests & friendships)
- `backend/src/models/chat.model.js` (Bảng Room & Message)
- `backend/src/routes/chat.routes.js` & `friend.routes.js`
- `backend/src/sockets/chat.socket.js` (Xử lý realtime events)
- `lucky_ly_mobile/lib/screens/friends/friend_management_screen.dart` (3 tabs)
- `lucky_ly_mobile/lib/screens/chat/chat_room_screen.dart`

## Task Breakdown (Chi tiết công việc)

### Phase 1: Database, Gift & Privacy Logic
- **Agent:** `backend-specialist` | **Skill:** `api-patterns, database-design`
1. **Task 1: Cập nhật cấu trúc DB (MongoDB)**
   - **Thêm/Sửa Models:** `Gift` (thêm expiresAt=24h, isCancelled, maxReceivers), `Friend` (status: pending/accepted), `Message`/`Room` (chat_logic), `User` (privacySettings).
   - **OUTPUT:** Các files Mongoose models chuẩn.
2. **Task 2: API Quản lý Bạn bè & Privacy**
   - **Nhiệm vụ:** API Gửi/Nhận/Hủy lời mời kết bạn; API Search Username (lọc các kết quả có setting ẩn mình = `true`).
3. **Task 3: API Quà tặng (Expiration, Multiple receivers & Cancel)**
   - **Nhiệm vụ:** API Generate QR (được 24h), API Cancel gift, API Claim gift (cộng quà vào inventory, báo lỗi nếu expired hoặc max receives).

### Phase 2: Realtime Chat Backend & Push Notification
- **Agent:** `backend-specialist` | **Skill:** `nodejs-best-practices, websocket`
4. **Task 4: Socket.io Integration cho Chat**
   - **Nhiệm vụ:** Xây dựng connection và các events `join_room`, `send_message`, `receive_message`.
   - **Guard (Chặn người lạ):** Middleware socket kiểm tra nếu chưa kết bạn -> Message count = 0 -> Chỉ cho gửi đúng 1 message "Tặng quà", nếu đã gửi >0 -> throw error!
5. **Task 5: Tích hợp FCM Notifications**
   - **Nhiệm vụ:** Khi gửi lời mời, khi gửi gift qua chat, phát Trigger FCM thông báo đẩy cho Client tương ứng.

### Phase 3: Mobile UI & Frontend Integration
- **Agent:** `mobile-developer` | **Skill:** `mobile-design`
6. **Task 6: Màn hình quản lý Bạn bè**
   - **Nhiệm vụ:** Màn hình quản lý chia 3 Tab (Lời mời đã nhận, Lời mời đã gửi, Danh sách).
7. **Task 7: Chat Screen & Gift UI**
   - **Nhiệm vụ:** Tích hợp màn Chat giao tiếp Socket.io. Hiển thị thông báo "Bạn và ... chưa là bạn bè..." / Alert cảnh báo. UI tạo quà (chọn số lượng người, expiration, QR).
8. **Task 8: QR Scanner & Deep Link & Settings**
   - **Nhiệm vụ:** Xử lý open link từ bên ngoài/scanner. Thêm Switch (Toggle) settings trong trang Profile cho phép "Ẩn tài khoản khỏi tìm kiếm".

## Phase X: Verification (Kiểm tra cuối cùng)
- [ ] Logic chặn Chat: Set up 2 user không là bạn bè, thử gửi 2 messages -> tin số 2 bị khoá. 
- [ ] Logic QR: Giả thời gian qua 24h, quét -> "QR Đã Hết Hạn". Thu hồi quà, quét -> "Quà đã bị thu hồi".
- [ ] Privacy check: Text username đang bật "Ẩn mình" -> Server báo tìm không thấy.
- [ ] Audit Mobile UX: Đảm bảo responsive theo phong cách design hiện hữu.
- [ ] Security: Chạy `npm run lint` & kiểm tra rò rỉ JWT, token.
