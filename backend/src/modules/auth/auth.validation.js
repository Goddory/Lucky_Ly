import { z } from 'zod';

const passwordRule = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,72}$/;

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
});

export const refreshSchema = z.object({
  refreshToken: z.string().min(40).max(500)
});

export const googleLoginSchema = z.object({
  idToken: z.string().min(100).max(5000).optional(),
  accessToken: z.string().min(10).max(5000).optional()
}).refine(data => data.idToken || data.accessToken, {
  message: 'Either idToken or accessToken is required'
});
