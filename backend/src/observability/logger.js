import { context, trace } from '@opentelemetry/api';
import winston from 'winston';

const withTraceContext = winston.format((info) => {
  const activeSpan = trace.getSpan(context.active());
  const spanContext = activeSpan?.spanContext();

  if (spanContext) {
    info.trace_id = info.trace_id || spanContext.traceId;
    info.span_id = info.span_id || spanContext.spanId;
  }

  return info;
});

export const getCurrentTraceContext = () => {
  const activeSpan = trace.getSpan(context.active());
  const spanContext = activeSpan?.spanContext();

  return {
    trace_id: spanContext?.traceId,
    span_id: spanContext?.spanId
  };
};

export const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  defaultMeta: {
    service: process.env.OTEL_SERVICE_NAME || 'rps-backend',
    environment: process.env.NODE_ENV || 'development'
  },
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    withTraceContext(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console()
  ]
});

