import { z } from 'zod';

const passwordRule = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,72}$/;

const sessionDeviceInfoSchema = z.object({
  deviceId: z.string().trim().min(1).max(255).optional(),
  deviceName: z.string().trim().min(1).max(255).optional(),
  platform: z.string().trim().min(1).max(50).optional()
});

export const registerSchema = z.object({
  username: z.string().trim().min(3).max(50),
  email: z.string().trim().email().max(255),
  fullName: z.string().trim().min(2).max(150),
  password: z.string().regex(passwordRule, 'Password must be 8-72 chars and include upper, lower, number, special char'),
  avatarUrl: z.string().url().max(1000).optional()
});

export const loginSchema = z.object({
  login: z.string().trim().min(3).max(255),
  password: z.string().min(8).max(72)
}).merge(sessionDeviceInfoSchema);

export const refreshSchema = z.object({
  refreshToken: z.string().min(40).max(500)
}).merge(sessionDeviceInfoSchema);

export const logoutSchema = z.object({
  refreshToken: z.string().min(40).max(500)
});

export const revokeSessionSchema = z.object({
  tokenId: z.string().uuid('Invalid tokenId format')
});

export const facebookLoginSchema = z.object({
  facebookId: z.string().min(1, 'Facebook ID is required'),
  email: z.string().trim().email('Invalid email address').or(z.literal('')),
  name: z.string().min(1, 'Name is required'),
  avatarUrl: z.string().url('Invalid avatar URL').nullable().optional()
}).merge(sessionDeviceInfoSchema);

export const forgotPasswordSchema = z.object({
  email: z.string().trim().email('Invalid email format')
});

export const verifyOtpSchema = z.object({
  email: z.string().trim().email('Invalid email format'),
  otp: z.string().length(6, 'OTP must be exactly 6 digits').regex(/^\d+$/, 'OTP must contain only numbers')
});

export const resetPasswordSchema = z.object({
  email: z.string().trim().email('Invalid email format'),
  otp: z.string().length(6, 'OTP must be exactly 6 digits'),
  newPassword: z.string().regex(passwordRule, 'Password must be 8-72 chars and include upper, lower, number, special char')
});

const googleLoginBaseSchema = z.object({
  idToken: z.string().min(100).max(5000).nullable().optional(),
  accessToken: z.string().min(10).max(5000).nullable().optional()
}).merge(sessionDeviceInfoSchema);

export const googleLoginSchema = googleLoginBaseSchema.refine(data => data.idToken || data.accessToken, {
  message: 'Either idToken or accessToken is required'
});
