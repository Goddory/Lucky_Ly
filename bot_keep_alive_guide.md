# 🤖 Bộ Mã nguồn & Hướng dẫn Cài đặt Bot Keep-Alive

Dưới đây là mã nguồn hoàn chỉnh và hướng dẫn để bạn tự cài đặt con bot này lên **Google Apps Script**.

## 🛠 Hướng dẫn Cài đặt (5 phút)
1. Truy cập [script.google.com](https://script.google.com/) và nhấn **Dự án mới**.
2. Đổi tên dự án thành `Lucky Ly Bot`.
3. Trong file `Mã.gs` (hoặc tạo mới file `Code.gs`), hãy xóa hết code cũ và dán nội dung phần **1. Logic Backend** vào.
4. Nhấn nút dấu **+** cạnh chữ "Tệp" > Chọn **HTML**, đặt tên là `index` (file sẽ thành `index.html`).
5. Dán nội dung phần **2. Giao diện UI** vào file `index.html`.
6. Nhấn biểu tượng **Lưu** (hình ổ đĩa).
7. Nhấn nút **Triển khai** > **Triển khai mới**.
8. Chọn loại là **Ứng dụng web**. Trong phần "Ai có quyền truy cập", chọn **Bất kỳ ai**. Nhấn **Triển khai**.
9. Google sẽ yêu cầu cấp quyền (chọn tài khoản của bạn > Advanced > Go to Lucky Ly Bot > Allow).
10. Copy URL ứng dụng web được cấp để mở giao diện điều khiển.

---

## 1. Logic Backend (`Code.gs`)
```javascript
const TARGET_URL = "https://lucky-ly-api.onrender.com/api/health"; // Đường dẫn kiểm tra sức khỏe API

function doGet() {
  return HtmlService.createTemplateFromFile('index')
    .evaluate()
    .setTitle('Lucky Ly - Bot Keep Alive')
    .addMetaTag('viewport', 'width=device-width, initial-scale=1');
}

// Lấy thông tin trạng thái hiện tại
function getBotStatus() {
  const props = PropertiesService.getScriptProperties();
  return {
    isActive: props.getProperty('IS_ACTIVE') === 'true',
    interval: props.getProperty('INTERVAL') || '12',
    lastPing: props.getProperty('LAST_PING') || 'Chưa chạy',
    lastStatus: props.getProperty('LAST_STATUS') || 'N/A',
    emails: props.getProperty('EMAILS') || ''
  };
}

// Cập nhật cấu hình và quản lý Trigger
function updateConfig(config) {
  const props = PropertiesService.getScriptProperties();
  props.setProperties({
    'IS_ACTIVE': config.isActive.toString(),
    'INTERVAL': config.interval.toString(),
    'EMAILS': config.emails
  });
  
  manageTrigger(config.isActive, parseInt(config.interval));
  return { success: true };
}

function manageTrigger(activate, intervalMinutes) {
  const triggers = ScriptApp.getProjectTriggers();
  triggers.forEach(t => ScriptApp.deleteTrigger(t));
  
  if (activate) {
    ScriptApp.newTrigger('pingServer')
      .timeBased()
      .everyMinutes(getValidInterval(intervalMinutes))
      .create();
  }
}

// Google Apps Script giới hạn một số mốc thời gian cố định cho trigger
function getValidInterval(min) {
  const valid = [1, 5, 10, 15, 30]; // Các mốc phút cho phép
  if (min <= 12) return 10; // Nếu chọn 12p, chạy mỗi 10p cho chắc
  return 30; // Nếu chọn trên 1h, dùng trigger lớn nhất là 30p rồi xử lý logic đếm sau (với bộ này đơn giản nhất là chọn mốc 10p)
}

// Hàm chính để ping server
function pingServer() {
  const props = PropertiesService.getScriptProperties();
  if (props.getProperty('IS_ACTIVE') !== 'true') return;

  const now = new Date().toLocaleString("vi-VN", {timeZone: "Asia/Ho_Chi_Minh"});
  try {
    const response = UrlFetchApp.fetch(TARGET_URL, { muteHttpExceptions: true });
    const code = response.getResponseCode();
    
    props.setProperty('LAST_PING', now);
    props.setProperty('LAST_STATUS', code == 200 ? "Thành công" : "Lỗi " + code);
    
    if (code !== 200) {
      sendAlertMessage("Cảnh báo: Server trả về mã lỗi " + code);
    }
  } catch (e) {
    props.setProperty('LAST_STATUS', "Không thể kết nối");
    sendAlertMessage("Lỗi kết nối: " + e.toString());
  }
}

function sendAlertMessage(msg) {
  const emails = PropertiesService.getScriptProperties().getProperty('EMAILS');
  if (!emails) return;
  
  const now = new Date().toLocaleString("vi-VN", {timeZone: "Asia/Ho_Chi_Minh"});
  MailApp.sendEmail({
    to: emails,
    subject: "⚠️ Báo động Lucky Ly API",
    body: `Cảnh báo hệ thống:\n\n${msg}\nThời gian: ${now}\nURL: ${TARGET_URL}`
  });
}
```

---

## 2. Giao diện UI (`index.html`)
```html
<!DOCTYPE html>
<html>
<head>
    <base target="_top">
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary: #6366f1;
            --bg: #0f172a;
            --card: #1e293b;
            --text: #f8fafc;
        }
        body {
            font-family: 'Outfit', sans-serif;
            background-color: var(--bg);
            color: var(--text);
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
        }
        .container {
            background: var(--card);
            padding: 2rem;
            border-radius: 24px;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
            width: 90%;
            max-width: 400px;
            text-align: center;
        }
        h1 { font-size: 1.5rem; margin-bottom: 1.5rem; color: var(--primary); }
        .status-box {
            background: rgba(255,255,255,0.05);
            padding: 1rem;
            border-radius: 16px;
            margin-bottom: 1.5rem;
            font-size: 0.9rem;
        }
        .toggle-container { margin: 1.5rem 0; }
        .switch {
            position: relative;
            display: inline-block;
            width: 60px;
            height: 34px;
        }
        .switch input { opacity: 0; width: 0; height: 0; }
        .slider {
            position: absolute;
            cursor: pointer;
            top: 0; left: 0; right: 0; bottom: 0;
            background-color: #334155;
            transition: .4s;
            border-radius: 34px;
        }
        .slider:before {
            position: absolute;
            content: "";
            height: 26px; width: 26px;
            left: 4px; bottom: 4px;
            background-color: white;
            transition: .4s;
            border-radius: 50%;
        }
        input:checked + .slider { background-color: var(--primary); }
        input:checked + .slider:before { transform: translateX(26px); }
        
        select, input[type="text"] {
            width: 100%;
            padding: 10px;
            margin: 10px 0;
            border-radius: 8px;
            border: 1px solid #334155;
            background: #0f172a;
            color: white;
            box-sizing: border-box;
        }
        button {
            background: var(--primary);
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 12px;
            cursor: pointer;
            width: 100%;
            font-weight: 600;
            margin-top: 1rem;
        }
        .loading { opacity: 0.5; pointer-events: none; }
    </style>
</head>
<body>
    <div class="container" id="app">
        <h1>Lucky Ly Bot Manager</h1>
        
        <div class="status-box">
            <div>Trạng thái cuối: <b id="lastStatus">Đang tải...</b></div>
            <div>Lần chạy cuối: <span id="lastPing">-</span></div>
        </div>

        <div class="toggle-container">
            <label class="switch">
                <input type="checkbox" id="botActive">
                <span class="slider"></span>
            </label>
            <p>Trạng thái Bot: <span id="toggleText">Tắt</span></p>
        </div>

        <label>Khoảng thời gian:</label>
        <select id="interval">
            <option value="12">Mỗi 12 phút (Khuyên dùng)</option>
            <option value="60">Mỗi 1 giờ</option>
            <option value="120">Mỗi 2 giờ</option>
            <option value="720">Mỗi 12 giờ</option>
        </select>

        <label>Email thông báo (dấu phẩy để ngăn cách):</label>
        <input type="text" id="emails" placeholder="name@gmail.com, boss@gmail.com">

        <button onclick="saveConfig()">Lưu Cài Đặt</button>
    </div>

    <script>
        function loadData() {
            google.script.run.withSuccessHandler(data => {
                document.getElementById('botActive').checked = data.isActive;
                document.getElementById('interval').value = data.interval;
                document.getElementById('lastPing').innerText = data.lastPing;
                document.getElementById('lastStatus').innerText = data.lastStatus;
                document.getElementById('emails').value = data.emails;
                updateToggleText(data.isActive);
            }).getBotStatus();
        }

        function updateToggleText(active) {
            document.getElementById('toggleText').innerText = active ? "Đang BẬT" : "Đang TẮT";
            document.getElementById('toggleText').style.color = active ? "#4ade80" : "#fb7185";
        }

        document.getElementById('botActive').onchange = (e) => updateToggleText(e.target.checked);

        function saveConfig() {
            const btn = document.querySelector('button');
            btn.classList.add('loading');
            btn.innerText = "Đang lưu...";
            
            const config = {
                isActive: document.getElementById('botActive').checked,
                interval: document.getElementById('interval').value,
                emails: document.getElementById('emails').value
            };
            
            google.script.run.withSuccessHandler(() => {
                btn.classList.remove('loading');
                btn.innerText = "Đã lưu thành công!";
                setTimeout(() => btn.innerText = "Lưu Cài Đặt", 2000);
            }).updateConfig(config);
        }

        loadData();
        setInterval(loadData, 30000); // Tự động cập nhật trạng thái mỗi 30s
    </script>
</body>
</html>
```
