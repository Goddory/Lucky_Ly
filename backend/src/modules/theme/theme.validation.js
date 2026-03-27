import { z } from 'zod';

export const setGlobalThemeSchema = z.object({
  theme: z.enum(['default', 'tet', 'valentine'])
});