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

export const facebookLoginSchema = z.object({
  facebookId: z.string().min(1).max(255),
  email: z.string().email().max(255).optional().or(z.literal('')),
  name: z.string().min(1).max(150),
  avatarUrl: z.string().url().max(1000).optional()
});
