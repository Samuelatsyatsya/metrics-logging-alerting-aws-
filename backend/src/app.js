import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import gameRoutes from './routes/game.routes.js';
import { errorHandler } from './middleware/errorHandler.js';
import { HTTP_STATUS } from './config/constants.js';
import { metricsMiddleware } from './middleware/metricsMiddleware.js';
import { requestLoggingMiddleware } from './middleware/requestLoggingMiddleware.js';
import { register } from './utils/metrics.js';

const app = express();
const API_PREFIX = process.env.API_PREFIX || '/api/v1';

// Security middleware
app.use(helmet());

// CORS configuration
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',  
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  preflightContinue: false,
  optionsSuccessStatus: 204
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 900000,
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 1000,
  message: {
    success: false,
    message: 'Too many requests from this IP, please try again later.'
  }
});
app.use(API_PREFIX, limiter);

// Body parsing middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request-scoped logs (JSON) with request_id and trace/span correlation.
app.use(requestLoggingMiddleware);

// Metrics middleware (before routes)
app.use(metricsMiddleware);

// Prometheus metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(HTTP_STATUS.OK).json({
    success: true,
    message: 'Server is healthy',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV
  });
});

// API routes
app.use(`${API_PREFIX}/game`, gameRoutes);

// Add API health endpoint
app.get(`${API_PREFIX}/health`, (req, res) => {
  res.status(HTTP_STATUS.OK).json({
    success: true,
    status: 'online',
    message: 'API is healthy',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(HTTP_STATUS.NOT_FOUND).json({
    success: false,
    message: `Route ${req.originalUrl} not found`
  });
});

// Error handling middleware 
app.use(errorHandler);

export default app;
