import { z } from 'zod';

import { supportedAppLocaleCodes } from '../../localization/supported-locales.js';
import {
  marketCategories,
  marketUnits,
} from '../repositories/market-product-repository.js';

/**
 * `en` is mandatory because it is the fallback every other locale resolves
 * to; the remaining keys are optional and must be locales the app can show.
 */
const localizedText = z
  .object({ en: z.string().trim().min(1).max(200) })
  .catchall(z.string().trim().min(1).max(200))
  .refine(
    (value) =>
      Object.keys(value).every((key) =>
        (supportedAppLocaleCodes as readonly string[]).includes(key),
      ),
    { message: 'contains a language the app does not support' },
  );

export const marketProductBodySchema = z.object({
  name: localizedText,
  description: localizedText,
  category: z.enum(marketCategories),
  price: z.number().int().positive().max(10_000_000),
  unit: z.enum(marketUnits),
  stockQuantity: z.number().int().min(0).max(1_000_000),
  vendor: z.string().trim().min(1).max(120),
  isActive: z.boolean().default(true),
});

export const marketProductQuerySchema = z.object({
  category: z.enum(marketCategories).optional(),
  search: z.string().trim().min(1).max(80).optional(),
  language: z.enum(supportedAppLocaleCodes).optional(),
});

export const marketProductIdSchema = z.object({
  id: z.string().trim().min(1).max(100),
});
