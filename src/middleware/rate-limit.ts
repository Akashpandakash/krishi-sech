import type { RequestHandler } from 'express';

interface RateLimitEntry {
  count: number;
  resetAt: number;
}

export function createRateLimiter(options: {
  windowMs: number;
  maxRequests: number;
  scope: string;
}): RequestHandler {
  const entries = new Map<string, RateLimitEntry>();
  return (request, response, next) => {
    const now = Date.now();
    const key = `${options.scope}:${request.ip || request.socket.remoteAddress || 'unknown'}`;
    const current = entries.get(key);
    const entry = !current || current.resetAt <= now
      ? { count: 0, resetAt: now + options.windowMs }
      : current;
    entry.count += 1;
    entries.set(key, entry);
    if (entries.size > 10_000) {
      for (const [entryKey, value] of entries) {
        if (value.resetAt <= now) entries.delete(entryKey);
      }
    }
    response.setHeader('RateLimit-Limit', options.maxRequests.toString());
    response.setHeader(
      'RateLimit-Remaining',
      Math.max(0, options.maxRequests - entry.count).toString(),
    );
    response.setHeader(
      'RateLimit-Reset',
      Math.ceil(entry.resetAt / 1000).toString(),
    );
    if (entry.count > options.maxRequests) {
      response.setHeader(
        'Retry-After',
        Math.max(1, Math.ceil((entry.resetAt - now) / 1000)).toString(),
      );
      response.status(429).json({
        success: false,
        error: {
          code: 'RATE_LIMITED',
          message: 'Too many requests. Please try again later',
        },
        requestId: response.locals.requestId,
      });
      return;
    }
    next();
  };
}
