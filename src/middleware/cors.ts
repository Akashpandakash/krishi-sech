import type { RequestHandler } from 'express';

export function createCorsMiddleware(
  allowedOrigins: readonly string[],
): RequestHandler {
  const allowed = new Set(allowedOrigins);
  const allowAny = allowed.has('*');
  return (request, response, next) => {
    const origin = request.get('origin');
    if (!origin) {
      next();
      return;
    }
    if (!allowAny && !allowed.has(origin)) {
      response.status(403).json({
        success: false,
        error: { code: 'ORIGIN_NOT_ALLOWED', message: 'Origin is not allowed' },
        requestId: response.locals.requestId,
      });
      return;
    }
    response.setHeader('Access-Control-Allow-Origin', allowAny ? '*' : origin);
    response.setHeader('Vary', 'Origin');
    response.setHeader(
      'Access-Control-Allow-Headers',
      'Authorization, Content-Type, X-Request-ID',
    );
    response.setHeader(
      'Access-Control-Allow-Methods',
      'GET, POST, PUT, DELETE, OPTIONS',
    );
    if (request.method === 'OPTIONS') {
      response.sendStatus(204);
      return;
    }
    next();
  };
}
