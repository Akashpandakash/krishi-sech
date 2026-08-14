import { z } from 'zod';

import {
  calendarTaskStatuses,
  calendarTaskTypes,
} from '../repositories/calendar-task-repository.js';

export const calendarTaskIdSchema = z.object({ id: z.string().trim().min(1).max(200) });

const fields = {
  cropId: z.uuid(),
  taskType: z.enum(calendarTaskTypes),
  dueDate: z.iso.datetime().transform((value) => new Date(value)),
  status: z.enum(calendarTaskStatuses),
  notes: z.string().trim().max(2000).nullable().optional().default(null),
  reminderEnabled: z.boolean(),
};

export const createCalendarTaskSchema = z.object({
  id: z.string().trim().min(1).max(200),
  ...fields,
});

export const updateCalendarTaskSchema = z.object(fields);
