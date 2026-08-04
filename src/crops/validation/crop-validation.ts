import { z } from 'zod';

import {
  cropHealthStatuses,
  growthStages,
  irrigationMethods,
  landUnits,
  soilTypes,
} from '../repositories/crop-repository.js';

const nullableDate = z
  .union([z.iso.date(), z.iso.datetime(), z.null()])
  .transform((value) => (value === null ? null : new Date(value)));

export const cropIdSchema = z.object({ id: z.uuid() });

export const cropBodySchema = z
  .object({
    cropName: z.string().trim().min(1).max(100),
    variety: z.string().trim().min(1).max(100),
    sowingDate: z
      .union([z.iso.date(), z.iso.datetime()])
      .transform((value) => new Date(value)),
    growthStage: z.enum(growthStages),
    landArea: z.number().positive().finite(),
    landUnit: z.enum(landUnits),
    soilType: z.enum(soilTypes),
    irrigationMethod: z.enum(irrigationMethods),
    expectedHarvestDate: nullableDate.optional().default(null),
    healthStatus: z.enum(cropHealthStatuses).optional().default('healthy'),
    notes: z.string().trim().max(2000).nullable().optional().default(null),
  })
  .refine((input) => input.sowingDate.getTime() <= Date.now(), {
    path: ['sowingDate'],
    message: 'Sowing date cannot be in the future',
  })
  .refine(
    (input) =>
      input.expectedHarvestDate === null ||
      input.expectedHarvestDate >= input.sowingDate,
    {
      path: ['expectedHarvestDate'],
      message: 'Expected harvest date cannot be before sowing date',
    },
  );
