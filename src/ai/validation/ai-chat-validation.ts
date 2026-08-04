import { z } from 'zod';

export const aiChatSchema = z.object({
  message: z.string().trim().min(1).max(2000),
  language: z.enum(['bn', 'en', 'hi']).default('bn'),
  history: z
    .array(
      z.object({
        role: z.enum(['user', 'assistant']),
        content: z.string().trim().min(1).max(2000),
      }),
    )
    .max(12)
    .default([]),
});
