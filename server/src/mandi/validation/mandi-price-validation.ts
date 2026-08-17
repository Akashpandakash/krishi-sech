import { z } from 'zod';

import { mandiPriceSources } from '../repositories/mandi-price-repository.js';

/** Upstream filter values are echoed into a query string, so keep them tight. */
const filterValue = z
  .string()
  .trim()
  .min(1)
  .max(80)
  .regex(/^[\p{L}\p{N} .,'()\-&]+$/u, 'contains unsupported characters');

const optionalFilterValue = filterValue
  .nullish()
  .transform((value) => value ?? null);

const rupeesPerQuintal = z.number().int().min(1).max(10_000_000);

export const mandiPriceQuerySchema = z.object({
  state: filterValue,
  district: filterValue.optional(),
  commodity: filterValue.optional(),
});

export const adminMandiListQuerySchema = z.object({
  state: filterValue.optional(),
  district: filterValue.optional(),
  commodity: filterValue.optional(),
  source: z.enum(mandiPriceSources).optional(),
  search: z.string().trim().min(1).max(80).optional(),
  limit: z.coerce.number().int().min(1).max(500).default(100),
});

export const adminMandiPriceBodySchema = z
  .object({
    state: filterValue,
    district: filterValue,
    market: filterValue,
    commodity: filterValue,
    variety: optionalFilterValue,
    grade: optionalFilterValue,
    arrivalDate: z.coerce
      .date()
      // The record id is derived from the day, so the time part must not vary.
      .transform(
        (value) =>
          new Date(
            Date.UTC(
              value.getUTCFullYear(),
              value.getUTCMonth(),
              value.getUTCDate(),
            ),
          ),
      ),
    minPrice: rupeesPerQuintal,
    maxPrice: rupeesPerQuintal,
    modalPrice: rupeesPerQuintal,
  })
  .refine((value) => value.minPrice <= value.modalPrice, {
    path: ['modalPrice'],
    message: 'must be at least the minimum price',
  })
  .refine((value) => value.modalPrice <= value.maxPrice, {
    path: ['maxPrice'],
    message: 'must be at least the modal price',
  });

export const adminMandiIdSchema = z.object({
  id: z.string().trim().min(1).max(300),
});
