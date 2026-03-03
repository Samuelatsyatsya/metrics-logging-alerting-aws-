import dotenv from 'dotenv';
import { DiagConsoleLogger, DiagLogLevel, diag } from '@opentelemetry/api';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { NodeSDK } from '@opentelemetry/sdk-node';

dotenv.config();

const serviceName = process.env.OTEL_SERVICE_NAME || 'rps-backend';
const baseOtlpEndpoint = (process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://jaeger:4318').replace(/\/+$/, '');
const tracesEndpoint = process.env.OTEL_EXPORTER_OTLP_TRACES_ENDPOINT || `${baseOtlpEndpoint}/v1/traces`;

if (process.env.OTEL_DIAGNOSTIC_LOGGING === 'true') {
  diag.setLogger(new DiagConsoleLogger(), DiagLogLevel.INFO);
}

const traceExporter = new OTLPTraceExporter({
  url: tracesEndpoint
});

const sdk = new NodeSDK({
  serviceName,
  traceExporter,
  instrumentations: [
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-http': { enabled: true },
      '@opentelemetry/instrumentation-express': { enabled: true },
      '@opentelemetry/instrumentation-mysql2': { enabled: true },
      '@opentelemetry/instrumentation-fs': { enabled: false }
    })
  ]
});

let tracingStarted = false;

try {
  await sdk.start();
  tracingStarted = true;
  console.log(JSON.stringify({
    level: 'info',
    message: 'OpenTelemetry tracing initialized',
    service: serviceName,
    traces_endpoint: tracesEndpoint
  }));
} catch (error) {
  console.error(JSON.stringify({
    level: 'error',
    message: 'Failed to initialize OpenTelemetry tracing',
    service: serviceName,
    traces_endpoint: tracesEndpoint,
    error: error?.message
  }));
}

export const shutdownTracing = async () => {
  if (!tracingStarted) {
    return;
  }

  try {
    await sdk.shutdown();
    tracingStarted = false;
    console.log(JSON.stringify({
      level: 'info',
      message: 'OpenTelemetry tracing shut down'
    }));
  } catch (error) {
    console.error(JSON.stringify({
      level: 'error',
      message: 'Failed to shut down OpenTelemetry tracing',
      error: error?.message
    }));
  }
};

