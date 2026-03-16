import { facebookLoginSchema, googleLoginSchema, loginSchema, refreshSchema, registerSchema, forgotPasswordSchema, verifyOtpSchema, resetPasswordSchema } from './auth.validation.js';
import { loginFacebookUser, loginUser, loginWithGoogle, registerUser, revokeRefreshToken, rotateRefreshToken, requestPasswordReset, verifyPasswordResetOtp, resetPasswordWithOtp } from './auth.service.js';

// Xử lý đăng ký tài khoản mới, validate input và trả access/refresh token.
export async function register(req, res, next) {
  try {
    const payload = registerSchema.parse(req.body);
    const result = await registerUser(payload);

    res.status(201).json({
      message: 'Register successful',
      user: result.user,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken
    });
  } catch (err) {
    next(err);
  }
}

// Xử lý đăng nhập bằng username/email + password, trả token phiên làm việc mới.
export async function login(req, res, next) {
  try {
    const payload = loginSchema.parse(req.body);
    const result = await loginUser(payload);

    res.status(200).json({
      message: result.message || 'Login successful',
      ...result
    });
  } catch (err) {
    next(err);
  }
}

// Xử lý đăng nhập bằng Facebook: verify Facebook token và trả token phiên.
export async function facebookLogin(req, res, next) {
  try {
    const payload = facebookLoginSchema.parse(req.body);
    const result = await loginFacebookUser(payload);

    res.status(200).json({
      message: result.message || 'Facebook login successful',
      ...result
    });
  } catch (err) {
    next(err);
  }
}

// Xử lý đăng nhập bằng Google: verify idToken hoặc accessToken và trả token phiên.
export async function googleLogin(req, res, next) {
  try {
    const payload = googleLoginSchema.parse(req.body);
    const result = await loginWithGoogle(payload);

    res.status(200).json({
      message: result.message || 'Google login successful',
      ...result
    });
  } catch (err) {
    next(err);
  }
}

// Xử lý làm mới access token bằng refresh token theo cơ chế rotation.
export async function refresh(req, res, next) {
  try {
    const payload = refreshSchema.parse(req.body);
    const result = await rotateRefreshToken(payload.refreshToken);

    res.status(200).json({
      message: 'Token refreshed',
      accessToken: result.accessToken,
      refreshToken: result.refreshToken
    });
  } catch (err) {
    next(err);
  }
}

// Xử lý đăng xuất: thu hồi refresh token hiện tại để vô hiệu hóa phiên.
export async function logout(req, res, next) {
  try {
    const payload = refreshSchema.parse(req.body);
    await revokeRefreshToken(payload.refreshToken);

    res.status(200).json({
      message: 'Logout successful'
    });
  } catch (err) {
    next(err);
  }
}

// Yêu cầu quên mật khẩu
export async function forgotPassword(req, res, next) {
  try {
    const payload = forgotPasswordSchema.parse(req.body);
    await requestPasswordReset(payload.email);
    res.status(200).json({
      message: 'If the email exists, an OTP has been sent.'
    });
  } catch (err) {
    next(err);
  }
}

// Xác thực OTP
export async function verifyOtp(req, res, next) {
  try {
    const payload = verifyOtpSchema.parse(req.body);
    await verifyPasswordResetOtp(payload.email, payload.otp);
    res.status(200).json({
      message: 'OTP verified successfully'
    });
  } catch (err) {
    next(err);
  }
}

// Đổi mật khẩu
export async function resetPassword(req, res, next) {
  try {
    const payload = resetPasswordSchema.parse(req.body);
    await resetPasswordWithOtp(payload.email, payload.otp, payload.newPassword);
    res.status(200).json({
      message: 'Password has been reset successfully'
    });
  } catch (err) {
    next(err);
  }
}
