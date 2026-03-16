import sgMail from '@sendgrid/mail';
import { env } from '../config/env.js';

// Khởi tạo SendGrid với API Key
sgMail.setApiKey(env.sendgridApiKey);

export async function sendPasswordResetEmail(toEmail, otpCode, username) {
  const msg = {
    // Lưu ý: from email này "phải" được xác thực (Verified Sender) trên giao diện SendGrid của bạn.
    // Nếu bạn chưa verified, email gửi đi sẽ bị SendGrid chặn lỗi 403.
    from: `"Lucky Ly Support" <phankhanhnam22@gmail.com>`, // Hãy đổi thành sender email hợp lệ trên tài khoản của bạn
    to: toEmail,
    subject: 'Mã xác nhận Đặt lại mật khẩu - Lucky Ly',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; background-color: #f9f9f9; padding: 20px; border-radius: 10px;">
        <h2 style="color: #0ea5d8; text-align: center;">Đặt lại mật khẩu</h2>
        <p>Chào <strong>${username}</strong>,</p>
        <p>Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản Lucky Ly của bạn. Dưới đây là mã OTP xác thực:</p>
        
        <div style="background-color: #ffffff; padding: 20px; border-radius: 8px; text-align: center; margin: 20px 0; border: 1px solid #e0e0e0;">
          <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #1e293b;">${otpCode}</span>
        </div>
        
        <p style="color: #ef4444; font-size: 14px;"><strong>Lưu ý:</strong> Mã này sẽ hết hạn sau 15 phút. Tuyệt đối không chia sẻ mã này cho bất kỳ ai.</p>
        <p>Nếu bạn không yêu cầu đổi mật khẩu, vui lòng bỏ qua email này.</p>
        <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 20px 0;" />
        <p style="font-size: 12px; color: #9ca3af; text-align: center;">Đội ngũ hỗ trợ Lucky Ly</p>
      </div>
    `,
  };

  try {
    await sgMail.send(msg);
  } catch (error) {
    console.error('Error sending email with SendGrid:', error);
    if (error.response) {
      console.error(error.response.body);
    }
    throw new Error('Failed to send OTP email via SendGrid');
  }
}

