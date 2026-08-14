import { z } from 'zod';
import { supportedAppLocaleCodes } from '../../localization/supported-locales.js';

const optionalText = z.string().trim().max(120).nullable().optional();
export const updateUserProfileSchema = z
  .object({
    name: z.string().trim().min(2).max(100),
    preferredLanguage: z.enum(supportedAppLocaleCodes),
    profilePhotoUrl: z.string().trim().url().max(500).nullable().optional(),
    state: optionalText,
    district: optionalText,
    village: optionalText,
  })
  .strict();

export const updateFarmProfileSchema = z
  .object({
    farmName: z.string().trim().min(2).max(120),
    farmerType: z.string().trim().min(2).max(60),
    totalLandArea: z.number().positive().max(1000000),
    landUnit: z.string().trim().min(1).max(30),
    soilType: z.string().trim().min(1).max(60),
    irrigationSource: z.string().trim().min(1).max(80),
    mainCrops: z.array(z.string().trim().min(1).max(80)).max(20),
    coarseLocation: z.string().trim().max(160).nullable().optional(),
  })
  .strict();
