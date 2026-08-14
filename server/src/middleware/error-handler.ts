import type { ErrorRequestHandler, RequestHandler } from 'express';
import { ZodError } from 'zod';
import multer from 'multer';

import { AppError } from '../common/app-error.js';

export const notFoundHandler: RequestHandler = (_request, response) => {
  response.status(404).json({
    success: false,
    error: { code: 'NOT_FOUND', message: 'Route not found' },
    requestId: response.locals.requestId,
  });
};

export function createErrorHandler(options: {
  production: boolean;
  loggingEnabled: boolean;
}): ErrorRequestHandler {
  return (error: unknown, _request, response, _next) => {
    const requestId = response.locals.requestId;
    if (error instanceof multer.MulterError) {
      response.status(error.code === 'LIMIT_FILE_SIZE' ? 413 : 400).json({
        success: false,
        error: {
          code:
            error.code === 'LIMIT_FILE_SIZE'
              ? 'IMAGE_TOO_LARGE'
              : 'UPLOAD_ERROR',
          message:
            error.code === 'LIMIT_FILE_SIZE'
              ? 'Crop image must be 2 MB or smaller'
              : 'Crop image upload failed',
        },
        requestId,
      });
      return;
    }
    if (error instanceof ZodError) {
      response.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Request validation failed',
          details: error.issues.map((issue) => ({
            path: issue.path.join('.'),
            message: issue.message,
          })),
        },
        requestId,
      });
      return;
    }
    if (error instanceof AppError) {
      const message =
        options.production && error.statusCode >= 500
          ? 'Service temporarily unavailable'
          : error.message;
      response.status(error.statusCode).json({
        success: false,
        error: { code: error.code, message },
        requestId,
      });
      return;
    }
    if (options.loggingEnabled) {
      console.error(JSON.stringify({ event: 'unhandled_error', requestId }));
    }
    response.status(500).json({
      success: false,
      error: { code: 'INTERNAL_ERROR', message: 'Internal server error' },
      requestId,
    });
  };
}
