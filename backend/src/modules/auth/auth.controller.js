import { loginSchema, refreshSchema, registerSchema, googleLoginSchema } from './auth.validation.js';
import { loginUser, registerUser, revokeRefreshToken, rotateRefreshToken, loginWithGoogle } from './auth.service.js';

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
      message: 'Login successful',
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

// Xử lý đăng nhập bằng Google: verify idToken hoặc accessToken và trả token phiên.
export async function googleLogin(req, res, next) {
  try {
    const payload = googleLoginSchema.parse(req.body);
    const result = await loginWithGoogle(payload);

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
