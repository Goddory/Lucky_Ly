import { z } from 'zod';

export const updateProfileSchema = z.object({
  fullName: z.string().trim().min(2).max(150).optional(),
  email: z.string().trim().email().max(255).optional(),
  avatarUrl: z.string().url().max(1000).nullable().optional()
});
