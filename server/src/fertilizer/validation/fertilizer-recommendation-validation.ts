import { z } from 'zod';

export const fertilizerRecommendationQuerySchema = z.object({
  cropId: z.string().uuid().optional(),
  language: z.enum(['bn', 'en', 'hi']).default('en'),
});
