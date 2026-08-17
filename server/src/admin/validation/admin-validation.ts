import { z } from 'zod';

import { adminRoles } from '../repositories/admin-repository.js';
import {
  broadcastCategories,
  broadcastStatuses,
} from '../../broadcasts/repositories/broadcast-repository.js';

export const adminLoginSchema = z.object({
  email: z.string().trim().email().max(200),
  password: z.string().min(1).max(200),
});

export const adminRefreshSchema = z.object({
  refreshToken: z.string().min(10).max(4000),
});

export const adminCreateSchema = z.object({
  email: z.string().trim().email().max(200),
  name: z.string().trim().min(2).max(80),
  password: z.string().min(12).max(200),
  role: z.enum(adminRoles),
});

export const adminUpdateSchema = z
  .object({
    name: z.string().trim().min(2).max(80).optional(),
    role: z.enum(adminRoles).optional(),
    isActive: z.boolean().optional(),
  })
  .refine((value) => Object.keys(value).length > 0, {
    message: 'At least one field must be provided',
  });

export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1).max(200),
  newPassword: z.string().min(12).max(200),
});

export const resetPasswordSchema = z.object({
  newPassword: z.string().min(12).max(200),
});

export const idParamSchema = z.object({ id: z.string().min(1).max(100) });

export const growthQuerySchema = z.object({
  days: z.coerce.number().int().min(7).max(365).default(30),
});

export const activityQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(50).default(12),
});

export const userListQuerySchema = z.object({
  search: z.string().trim().max(100).optional(),
  status: z.enum(['all', 'active', 'blocked']).default('all'),
  language: z.string().trim().max(20).optional(),
  state: z.string().trim().max(80).optional(),
  sort: z.enum(['recent', 'oldest', 'crops', 'lastSeen']).default('recent'),
  page: z.coerce.number().int().min(1).max(10_000).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const userStatusSchema = z.object({ isActive: z.boolean() });

export const deleteUserSchema = z.object({
  reason: z.string().trim().min(3).max(300),
});

export const audienceSchema = z.object({
  language: z.string().trim().max(20).nullish().transform((v) => v ?? null),
  state: z.string().trim().max(80).nullish().transform((v) => v ?? null),
  farmerType: z.string().trim().max(40).nullish().transform((v) => v ?? null),
  onlyActive: z.boolean().default(true),
});

export const broadcastCreateSchema = z.object({
  title: z.string().trim().min(3).max(80),
  body: z.string().trim().min(3).max(500),
  category: z.enum(broadcastCategories).default('general'),
  deepLink: z
    .string()
    .trim()
    .max(200)
    .nullish()
    .transform((value) => value?.trim() || null),
  audience: audienceSchema.default({
    language: null,
    state: null,
    farmerType: null,
    onlyActive: true,
  }),
  scheduledAt: z.coerce.date().nullish().transform((value) => value ?? null),
  sendNow: z.boolean().default(false),
});

export const broadcastListQuerySchema = z.object({
  status: z.enum(broadcastStatuses).optional(),
  limit: z.coerce.number().int().min(1).max(200).default(50),
});

export const auditQuerySchema = z.object({
  action: z.string().trim().max(60).optional(),
  limit: z.coerce.number().int().min(1).max(200).default(50),
});

export const telemetryQuerySchema = z.object({
  days: z.coerce.number().int().min(1).max(90).default(28),
});
