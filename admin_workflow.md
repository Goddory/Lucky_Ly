---
description: Hướng dẫn sử dụng Admin Dashboard và Quản lý hệ thống Lucky Ly
---

# Lộ trình Quản lý Hệ thống (Admin Workflow)

Tài liệu này hướng dẫn cách truy cập và quản lý các chức năng quản trị trong ứng dụng Lucky Ly dành riêng cho tài khoản Quản trị viên (Admin).

## 1. Đăng nhập hệ thống

Admin đăng nhập vào ứng dụng bằng tài khoản chuẩn:
- **Email:** `admin@gmail.com`
- **Mật khẩu:** `Luckyly@2016`

## 2. Truy cập Admin Dashboard

- Sau khi đăng nhập thành công, điều hướng đến **Mục Tôi (Profile)**.
- Khi hệ thống nhận diện đúng email quản trị, màn hình sẽ hiển thị nút **Quản trị hệ thống (Admin Dashboard)** màu đỏ nổi bật trong phần Cài đặt.
- Nhấn vào nút này để vào Màn hình Quản trị.

## 3. Các chức năng Quản trị hiện có

Admin Dashboard được chia thành 3 tính năng chính:

### 3.1. Quản lý Người dùng (Users Management)
- Xem danh sách người dùng đăng ký trên hệ thống.
- Cập nhật trạng thái người dùng (Hoạt động / Khóa chặn).
- Nâng quyền hoặc phân số dư trực tiếp (nếu cần thiết).

### 3.2. Báo cáo & Thống kê (Statistics)
- Theo dõi các số liệu tổng quan của ứng dụng:
  - Tổng số người dùng đăng ký.
  - Tổng số lượng tin đăng/thuê mượn.
  - Tổng số giao dịch và trạng thái.
- Biểu đồ thống kê theo tuần/tháng để đưa ra phương án phát triển.

### 3.3. Quản lý Giao diện (Theme Management)
Lucky Ly cho phép thay đổi giao diện toàn hệ thống động (không cần update app qua store). Admin có thể chọn các Theme xây dựng sẵn:
- **Default (Premium):** Màu xanh Teal sâu và Vàng kim.
- **Tết Nguyên Đán:** Màu đỏ và vàng ánh kim đậm chất truyền thống.
- **Giáng Sinh:** Màu xanh lá cây và trắng tuyết.
- **Mùa Hè Sôi Động:** Màu cam và vàng nắng.

*Thao tác:* Admin chọn một Theme trong danh sách `-> Chọn "Lưu cấu hình" ->` Giao diện của tất cả người dùng sẽ được cập nhật đồng bộ sau khi họ khởi động lại hoặc load lại app.

## 4. Lưu ý Bảo mật
- Không chia sẻ tài khoản `admin@gmail.com` ra ngoài.
- Thường xuyên kiểm tra Audit Log (nếu có bổ sung sau này) để xem lịch sử thao tác của các Admin khác (Nếu hệ thống có nhiều Admin).
