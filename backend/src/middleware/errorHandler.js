import { HTTP_STATUS } from '../config/constants.js';
import { getCurrentTraceContext, logger } from '../observability/logger.js';

export const errorHandler = (err, req, res, next) => {
  const traceContext = getCurrentTraceContext();
  logger.error('request_failed', {
    request_id: req.requestId,
    method: req.method,
    path: req.originalUrl,
    status_code: err.statusCode || HTTP_STATUS.INTERNAL_SERVER_ERROR,
    error_name: err.name,
    error_message: err.message,
    trace_id: traceContext.trace_id,
    span_id: traceContext.span_id,
    stack: err.stack
  });

  // Sequelize validation error
  if (err.name === 'SequelizeValidationError') {
    const errors = err.errors.map(error => ({
      field: error.path,
      message: error.message
    }));
    
    return res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: 'Validation error',
      errors,
      request_id: req.requestId
    });
  }

  // Sequelize unique constraint error
  if (err.name === 'SequelizeUniqueConstraintError') {
    return res.status(HTTP_STATUS.CONFLICT).json({
      success: false,
      message: 'Resource already exists',
      field: err.errors[0].path,
      request_id: req.requestId
    });
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    return res.status(HTTP_STATUS.UNAUTHORIZED).json({
      success: false,
      message: 'Invalid token',
      request_id: req.requestId
    });
  }

  // Default error
  const statusCode = err.statusCode || HTTP_STATUS.INTERNAL_SERVER_ERROR;
  const message = err.message || 'Internal server error';

  res.status(statusCode).json({
    success: false,
    message,
    request_id: req.requestId,
    trace_id: traceContext.trace_id,
    span_id: traceContext.span_id,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};
