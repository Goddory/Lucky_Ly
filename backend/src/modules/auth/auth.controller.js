import { facebookLoginSchema, googleLoginSchema, loginSchema, refreshSchema, registerSchema, forgotPasswordSchema, verifyOtpSchema, resetPasswordSchema, logoutSchema, revokeSessionSchema } from './auth.validation.js';
import { loginFacebookUser, loginUser, loginWithGoogle, registerUser, revokeRefreshToken, rotateRefreshToken, requestPasswordReset, verifyPasswordResetOtp, resetPasswordWithOtp, listActiveSessions, revokeAllRefreshTokens, revokeSessionByTokenId } from './auth.service.js';

function buildSessionMeta(req, payload = {}) {
  return {
    deviceId: payload.deviceId,
    deviceName: payload.deviceName,
    platform: payload.platform,
    userAgent: req.get('user-agent') || null,
    ipAddress: req.ip || req.socket?.remoteAddress || null
  };
}

// Xử lý đăng ký tài khoản mới, validate input và trả access/refresh token.
export async function register(req, res, next) {
  try {
    const payload = registerSchema.parse(req.body);
    const result = await registerUser({ ...payload, ...buildSessionMeta(req, payload) });

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
    const result = await loginUser({ ...payload, ...buildSessionMeta(req, payload) });

    res.status(200).json({
      message: 'Login successful',
      user: result.user,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken
    });
  } catch (err) {
    next(err);
  }
}

// Xử lý đăng nhập bằng Facebook: verify Facebook token và trả token phiên.
export async function facebookLogin(req, res, next) {
  try {
    const payload = facebookLoginSchema.parse(req.body);
    const result = await loginFacebookUser({ ...payload, ...buildSessionMeta(req, payload) });

    res.status(200).json({
      message: 'Facebook login successful',
      user: result.user,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken
    });
  } catch (err) {
    next(err);
  }
}

// Xử lý đăng nhập bằng Google: verify idToken hoặc accessToken và trả token phiên.
export async function googleLogin(req, res, next) {
  try {
    const payload = googleLoginSchema.parse(req.body);
    const result = await loginWithGoogle({ ...payload, ...buildSessionMeta(req, payload) });

    res.status(200).json({
      message: 'Google login successful',
      user: result.user,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken
    });
  } catch (err) {
    next(err);
  }
}

// Xử lý làm mới access token bằng refresh token theo cơ chế rotation.
export async function refresh(req, res, next) {
  try {
    const payload = refreshSchema.parse(req.body);
    const result = await rotateRefreshToken(payload.refreshToken, buildSessionMeta(req, payload));

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
    const payload = logoutSchema.parse(req.body);
    await revokeRefreshToken(payload.refreshToken, req.user?.userId ?? null);

    res.status(200).json({
      message: 'Logout successful'
    });
  } catch (err) {
    next(err);
  }
}

// Trả danh sách phiên đăng nhập theo thiết bị đang hoạt động.
export async function sessions(req, res, next) {
  try {
    const data = await listActiveSessions(req.user.userId);
    res.status(200).json({ sessions: data });
  } catch (err) {
    next(err);
  }
}

// Thu hồi toàn bộ phiên của user hiện tại.
export async function logoutAll(req, res, next) {
  try {
    const revokedCount = await revokeAllRefreshTokens(req.user.userId);
    res.status(200).json({
      message: 'All sessions revoked successfully',
      revokedCount
    });
  } catch (err) {
    next(err);
  }
}

// Thu hồi 1 phiên theo token_id.
export async function logoutSession(req, res, next) {
  try {
    const payload = revokeSessionSchema.parse(req.body);
    const ok = await revokeSessionByTokenId(req.user.userId, payload.tokenId);

    if (!ok) {
      return res.status(404).json({ message: 'Session not found or already revoked' });
    }

    res.status(200).json({ message: 'Session revoked successfully' });
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
