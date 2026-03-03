import crypto from 'crypto';
import { getCurrentTraceContext, logger } from '../observability/logger.js';

const getRequestId = (existingRequestId) => {
  if (existingRequestId && typeof existingRequestId === 'string') {
    return existingRequestId;
  }

  if (typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID();
  }

  return `${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
};

export const requestLoggingMiddleware = (req, res, next) => {
  const startTimeNs = process.hrtime.bigint();
  const requestId = getRequestId(req.get('x-request-id'));
  const startTraceContext = getCurrentTraceContext();

  req.requestId = requestId;
  res.setHeader('x-request-id', requestId);

  res.on('finish', () => {
    const durationMs = Number(process.hrtime.bigint() - startTimeNs) / 1_000_000;
    const finishTraceContext = getCurrentTraceContext();
    const forwardedFor = req.get('x-forwarded-for');
    const remoteIp = forwardedFor ? forwardedFor.split(',')[0].trim() : req.socket?.remoteAddress;

    logger.info('request_completed', {
      request_id: requestId,
      trace_id: finishTraceContext.trace_id || startTraceContext.trace_id,
      span_id: finishTraceContext.span_id || startTraceContext.span_id,
      method: req.method,
      path: req.originalUrl,
      status_code: res.statusCode,
      duration_ms: Number(durationMs.toFixed(2)),
      user_agent: req.get('user-agent'),
      remote_ip: remoteIp
    });
  });

  next();
};
