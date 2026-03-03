import { httpRequestDuration, httpRequestErrorsTotal, httpRequestTotal } from '../utils/metrics.js';

const normalizeRoute = (req) => {
  const knownRoute = req.route?.path ? `${req.baseUrl || ''}${req.route.path}` : req.path;

  return knownRoute
    .replace(/\/[0-9]+(?=\/|$)/g, '/:id')
    .replace(/[0-9a-f]{8}-[0-9a-f-]{27,}/gi, ':id');
};

export const metricsMiddleware = (req, res, next) => {
  const startNs = process.hrtime.bigint();

  res.on('finish', () => {
    const durationSeconds = Number(process.hrtime.bigint() - startNs) / 1_000_000_000;
    const route = normalizeRoute(req);
    const statusCode = String(res.statusCode);
    const statusClass = `${Math.floor(res.statusCode / 100)}xx`;
    const labels = {
      method: req.method,
      route,
      status_code: statusCode,
      status_class: statusClass
    };

    httpRequestDuration.observe(labels, durationSeconds);
    httpRequestTotal.inc(labels);

    if (res.statusCode >= 400) {
      httpRequestErrorsTotal.inc(labels);
    }
  });

  next();
};
