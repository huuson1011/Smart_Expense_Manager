# Smart Expense Manager

Ứng dụng quản lý thu chi cá nhân được xây dựng bằng **Flutter**, hỗ trợ đồng bộ dữ liệu đa thiết bị qua Firebase.

---

## Nhóm thực hiện

**Nhóm 2**

Thành viên trong nhóm:
- Nguyễn Hữu Sơn - MSV: 20220667 (Trưởng Nhóm)
- Hoàng Thị Thảo Vân - MSV: 20221498

---

## Tính năng

### Quản lý giao dịch
- Thêm, sửa, xóa giao dịch thu/chi
- Phân loại theo danh mục: Ăn uống, Di chuyển, Mua sắm, hoặc tự tạo danh mục
- Chọn nguồn tiền: Tiền mặt / ATM
- Xem danh sách giao dịch sắp xếp theo ngày

### Tìm kiếm
- Tìm kiếm giao dịch theo tên, danh mục hoặc ví
- Kết quả lọc theo thời gian thực

### Thống kê
- Biểu đồ tròn (PieChart) cơ cấu **chi tiêu** và **thu nhập** theo tháng
- Chuyển qua lại giữa các tháng để xem lịch sử
- Tổng thu / tổng chi từng tháng

### Ngân sách
- Đặt hạn mức ngân sách theo từng danh mục
- Thanh tiến trình hiển thị mức độ chi tiêu
- Cảnh báo khi sắp chạm (≥80%) hoặc vượt (100%) hạn mức
- Xem ngân sách theo từng tháng bất kỳ

### Đăng nhập & Đồng bộ
- Đăng ký / đăng nhập bằng Email & Password
- Dữ liệu lưu trên **Cloud Firestore**, đồng bộ khi chuyển thiết bị
- Lưu cục bộ bằng **SharedPreferences** làm fallback khi offline
- Quên mật khẩu qua email reset

---

## Công nghệ sử dụng

| Thành phần | Công nghệ |
|-----------|-----------|
| Framework | Flutter |
| State Management | Provider |
| Authentication | Firebase Auth |
| Database (cloud) | Cloud Firestore |
| Database (local) | SharedPreferences |
| Biểu đồ | fl_chart |
| Định dạng tiền | intl |
| UUID | uuid |

---

## Cài đặt & Chạy

### Yêu cầu
- Flutter SDK ≥ 3.0
- Dart SDK ≥ 3.0
- Android SDK (minSdkVersion 21) hoặc Xcode (iOS)
- Tài khoản Firebase

### 1. Clone repository

```bash
git clone https://github.com/<your-username>/smart_expense_manager.git
cd smart_expense_manager
```

### 2. Cài dependencies

```bash
flutter pub get
```

### 3. Cấu hình Firebase

**a. Cài FlutterFire CLI:**
```bash
dart pub global activate flutterfire_cli
```

**b. Kết nối project Firebase:**
```bash
flutterfire configure
```
Lệnh này tự tạo file `lib/firebase_options.dart`.

**c. Cập nhật `main.dart`:**
```dart
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### 4. Bật dịch vụ Firebase

Trong [Firebase Console](https://console.firebase.google.com):

- **Authentication** → Sign-in method → bật **Email/Password**
- **Firestore Database** → Create database → Start in test mode

**Firestore Security Rules:**
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 5. Chạy ứng dụng

```bash
flutter run
```
