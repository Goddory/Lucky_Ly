# 🔐 Plan: Fix Facebook Login

## 📌 Mục tiêu
Xác định và sửa tất cả nguyên nhân khiến đăng nhập Facebook bị lỗi trong ứng dụng Flutter Lucky Ly.

---

## 🔍 Phân tích nguyên nhân lỗi (Root Cause Analysis)

### ❌ Lỗi #1 — Key Hash không khớp (Nguyên nhân phổ biến nhất)
**Vấn đề:**
Facebook yêu cầu Key Hash của ứng dụng Android phải được đăng ký trong Facebook Developer Console.
Nếu Key Hash debug (`~/.android/debug.keystore`) không được thêm vào Facebook App Settings → sẽ bị báo lỗi:
> `"An error occurred: Invalid Key Hash. The key hash ... does not match any stored key hashes."`

**Chứng cứ trong code:**
- `applicationId = "com.example.lucky_ly_mobile"` → đây là package name cần đăng ký
- `strings.xml` có `facebook_app_id = 2016157219330688` — nhưng App cần Key Hash tương ứng

**Cách sửa:**
```powershell
# Chạy lệnh này để lấy Key Hash debug
keytool -exportcert -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android | openssl sha1 -binary | openssl base64
```
→ Copy kết quả → Vào [Facebook Developer](https://developers.facebook.com/apps/2016157219330688/settings/basic/) → **Android → Key Hashes** → Add.

---

### ❌ Lỗi #2 — Facebook SDK version conflict
**Vấn đề:**
```kotlin
// build.gradle.kts
implementation("com.facebook.android:facebook-android-sdk:[4,5)")
```
Dùng range `[4,5)` → lock ở SDK v4.x (cũ, đã deprecated). Flutter plugin `flutter_facebook_auth` hiện yêu cầu SDK **v16+**.

**Cách sửa:**
```kotlin
// Thay bằng version cụ thể, mới nhất
implementation("com.facebook.android:facebook-android-sdk:17.0.1")
```

---

### ❌ Lỗi #3 — AndroidManifest.xml thiếu `<provider>` (Chrome Custom Tab)
**Vấn đề:**
Với Facebook SDK v13+, cần khai báo `FileProvider` để handle Chrome Custom Tab.
`AndroidManifest.xml` hiện tại **không có** `<provider>` cho Facebook.

**Cách sửa — thêm vào trong `<application>` tag:**
```xml
<provider
    android:name="com.facebook.FacebookContentProvider"
    android:authorities="com.facebook.app.FacebookContentProvider2016157219330688"
    android:exported="true" />
```

---

### ❌ Lỗi #4 — `flutter_facebook_auth` pubspec version
**Vấn đề:**
Cần kiểm tra `pubspec.yaml` để đảm bảo dùng phiên bản tương thích:
- `flutter_facebook_auth: ^6.0.0` (mới nhất, stable)

**Cách sửa:**
```yaml
dependencies:
  flutter_facebook_auth: ^7.0.0  # hoặc version mới nhất
```
Sau đó chạy: `flutter pub upgrade flutter_facebook_auth`

---

### ❌ Lỗi #5 — Backend endpoint `/api/auth/facebook-login` chưa có / lỗi
**Vấn đề:**
Code Flutter gửi POST đến `$_apiBaseUrl/api/auth/facebook-login` với body:
```json
{
  "facebookId": "...",
  "name": "...",
  "email": "...",
  "avatarUrl": "..."
}
```
Nếu backend chưa có route này hoặc logic bị lỗi → toàn bộ flow thất bại.

**Cần kiểm tra:**
- File route `/api/auth/facebook-login` tồn tại trong backend
- Logic upsert user theo `facebookId` hoạt động đúng
- Response trả về đúng format: `{ user: {...}, accessToken: "...", refreshToken: "..." }`

---

### ❌ Lỗi #6 — `catch (e)` bắt lỗi im lặng
**Vấn đề:**
```dart
} catch (e) {
  _showMessage('Facebook login error. Please try again.');
}
```
Lỗi thực sự bị ẩn đi — không biết lỗi gì cụ thể xảy ra.

**Cách sửa tạm thời để debug:**
```dart
} catch (e) {
  _showMessage('Facebook login error: $e');
  debugPrint('Facebook login error: $e');
}
```

---

## 📋 Checklist Sửa lỗi (Theo thứ tự ưu tiên)

| # | Việc cần làm | File cần sửa | Độ ưu tiên |
|---|---|---|---|
| 1 | Thêm Key Hash vào Facebook Developer Console | Facebook App Settings | 🔴 Critical |
| 2 | Nâng SDK version từ `[4,5)` → `17.0.1` | `android/app/build.gradle.kts` | 🔴 Critical |
| 3 | Thêm `<provider>` FacebookContentProvider vào Manifest | `android/app/src/main/AndroidManifest.xml` | 🟠 High |
| 4 | Nâng version `flutter_facebook_auth` trong pubspec | `pubspec.yaml` | 🟠 High |
| 5 | Mở rộng catch block để xem lỗi thật sự | `lib/main.dart` | 🟡 Medium |
| 6 | Kiểm tra backend endpoint `/api/auth/facebook-login` | Backend route files | 🟡 Medium |

---

## 🛠️ Các bước thực hiện chi tiết

### Bước 1: Lấy Key Hash và đăng ký Facebook
```powershell
keytool -exportcert -alias androiddebugkey `
  -keystore "$env:USERPROFILE\.android\debug.keystore" `
  -storepass android -keypass android | `
  openssl sha1 -binary | openssl base64
```
→ Đăng nhập [https://developers.facebook.com/apps/2016157219330688/settings/basic/](https://developers.facebook.com/apps/2016157219330688/settings/basic/)
→ Cuộn xuống **Android** → **Key Hashes** → Paste và Save.

### Bước 2: Sửa build.gradle.kts
```kotlin
dependencies {
    implementation("com.facebook.android:facebook-android-sdk:17.0.1")
}
```

### Bước 3: Thêm provider vào AndroidManifest.xml
```xml
<!-- Trong <application> tag, sau FacebookActivity -->
<provider
    android:name="com.facebook.FacebookContentProvider"
    android:authorities="com.facebook.app.FacebookContentProvider2016157219330688"
    android:exported="true" />
```

### Bước 4: Cập nhật pubspec.yaml
```yaml
flutter_facebook_auth: ^7.0.0
```
Sau đó: `flutter pub get`

### Bước 5: Thêm debug log trong Flutter
```dart
} catch (e) {
  debugPrint('[Facebook] Error: $e');
  _showMessage('Facebook error: $e'); // Tạm thời để debug
}
```

### Bước 6: Chạy lại app
```bash
flutter clean
flutter pub get
flutter run
```

---

## ✅ Điều kiện hoàn thành (Definition of Done)
- [ ] Nhấn nút Facebook → mở màn hình đăng nhập Facebook thành công
- [ ] Sau khi đồng ý quyền → app nhận được `facebookId`, `name`, `email`
- [ ] Backend trả về `accessToken` + `refreshToken`
- [ ] App navigate về `HomeScreen` thành công
- [ ] Không còn lỗi trong console/logcat

---

## 📁 Files liên quan
- `backend/lucky_ly_mobile/lib/main.dart` — Flutter login logic
- `backend/lucky_ly_mobile/android/app/build.gradle.kts` — SDK dependency
- `backend/lucky_ly_mobile/android/app/src/main/AndroidManifest.xml` — Manifest config
- `backend/lucky_ly_mobile/android/app/src/main/res/values/strings.xml` — Facebook credentials
- `pubspec.yaml` — Flutter dependencies
