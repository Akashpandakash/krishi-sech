import { z } from 'zod';

export const irrigationRecommendationQuerySchema = z.object({
  cropId: z.string().uuid().optional(),
  language: z.enum(['bn', 'en', 'hi']).default('en'),
  landType: z.enum(['upland', 'lowland', 'irrigated', 'rainfed']).optional(),
});
