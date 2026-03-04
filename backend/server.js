import { shutdownTracing } from "./src/observability/tracing.js";
import dotenv from "dotenv";
import { logger } from "./src/observability/logger.js";

// Load environment variables
dotenv.config();

const PORT = process.env.PORT || 5000;
const HOST = process.env.HOST || "0.0.0.0";

let metricsUpdaterInterval = null;
let httpServer = null;
let shuttingDown = false;
let sequelizeConnection = null;

const gracefulShutdown = async (signal) => {
  if (shuttingDown) {
    return;
  }

  shuttingDown = true;
  logger.info("shutdown_started", { signal });

  try {
    if (metricsUpdaterInterval) {
      clearInterval(metricsUpdaterInterval);
    }

    if (httpServer) {
      await new Promise((resolve) => httpServer.close(resolve));
    }

    if (sequelizeConnection) {
      await sequelizeConnection.close();
    }
    await shutdownTracing();
    logger.info("shutdown_completed", { signal });
    process.exit(0);
  } catch (error) {
    logger.error("shutdown_failed", { signal, error: error.message });
    process.exit(1);
  }
};

async function startServer() {
  try {
    // Load app/database only after tracing is initialized so HTTP/Express are instrumented.
    const [{ default: app }, dbModule, metricsUpdaterModule] = await Promise.all([
      import("./src/app.js"),
      import("./src/config/db.js"),
      import("./src/utils/metricsUpdater.js")
    ]);

    const { testConnection, sequelize } = dbModule;
    const { startMetricsUpdater } = metricsUpdaterModule;
    sequelizeConnection = sequelize;

    // Test database connection
    const dbConnected = await testConnection();

    if (!dbConnected) {
      logger.error("startup_failed_db_connection");
      await shutdownTracing();
      process.exit(1);
    }

    // Sync database models
    if (process.env.NODE_ENV === "development") {
      await sequelize.sync({ alter: true });
      logger.info("database_models_synchronized", { mode: "development", alter: true });
    } else if (process.env.NODE_ENV === "production") {
      // On first deployment, create tables if they don't exist
      await sequelize.sync({ alter: false });
      logger.info("database_models_synchronized", { mode: "production", alter: false });
    }

    // Start server
    httpServer = app.listen(PORT, HOST, () => {
      logger.info("server_started", {
        environment: process.env.NODE_ENV,
        host: `http://${HOST}:${PORT}`,
        health_url: `http://${HOST}:${PORT}/health`,
        metrics_url: `http://${HOST}:${PORT}/metrics`,
        api_url: `http://${HOST}:${PORT}${process.env.API_PREFIX || "/api/v1"}`,
        database: `${process.env.DB_NAME}@${process.env.DB_HOST}:${process.env.DB_PORT}`
      });

      metricsUpdaterInterval = startMetricsUpdater();
      logger.info("metrics_updater_started");
    });
  } catch (error) {
    logger.error("startup_failed", { error: error.message, stack: error.stack });
    await shutdownTracing();
    process.exit(1);
  }
}

// Handle uncaught exceptions
process.on("uncaughtException", (error) => {
  logger.error("uncaught_exception", { error: error.message, stack: error.stack });
  process.exit(1);
});

process.on("unhandledRejection", (error) => {
  logger.error("unhandled_rejection", { error: error?.message || String(error) });
});

// Graceful shutdown
process.on("SIGTERM", () => gracefulShutdown("SIGTERM"));
process.on("SIGINT", () => gracefulShutdown("SIGINT"));

startServer();
