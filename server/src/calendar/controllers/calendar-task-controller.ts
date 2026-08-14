import type { Response } from 'express';

import type { AuthenticatedRequest } from '../../auth/middleware/auth-middleware.js';
import { sendSuccess } from '../../common/response.js';
import type { CalendarTaskService } from '../services/calendar-task-service.js';
import {
  calendarTaskIdSchema,
  createCalendarTaskSchema,
  updateCalendarTaskSchema,
} from '../validation/calendar-task-validation.js';

export class CalendarTaskController {
  constructor(private readonly service: CalendarTaskService) {}

  create = async (request: AuthenticatedRequest, response: Response) => {
    const task = await this.service.create(
      request.auth!.userId,
      createCalendarTaskSchema.parse(request.body),
    );
    return sendSuccess(response, 201, 'Calendar task created successfully', task);
  };

  list = async (request: AuthenticatedRequest, response: Response) =>
    sendSuccess(
      response,
      200,
      'Calendar tasks retrieved successfully',
      await this.service.list(request.auth!.userId),
    );

  update = async (request: AuthenticatedRequest, response: Response) => {
    const { id } = calendarTaskIdSchema.parse(request.params);
    const task = await this.service.update(
      request.auth!.userId,
      id,
      updateCalendarTaskSchema.parse(request.body),
    );
    return sendSuccess(response, 200, 'Calendar task updated successfully', task);
  };

  delete = async (request: AuthenticatedRequest, response: Response) => {
    const { id } = calendarTaskIdSchema.parse(request.params);
    await this.service.delete(request.auth!.userId, id);
    return sendSuccess(response, 200, 'Calendar task deleted successfully');
  };
}
