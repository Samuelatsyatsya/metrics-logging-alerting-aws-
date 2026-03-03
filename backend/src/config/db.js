import { Sequelize } from 'sequelize';
import dotenv from 'dotenv';
import { databaseQueryDuration } from '../utils/metrics.js';
import { logger } from '../observability/logger.js';

dotenv.config();

const getQueryOperation = (sql) => {
  if (!sql || typeof sql !== 'string') {
    return 'UNKNOWN';
  }

  const operation = sql.trim().split(/\s+/)[0];
  return (operation || 'UNKNOWN').toUpperCase();
};

const sequelize = new Sequelize(
  process.env.DB_NAME,
  process.env.DB_USER,
  process.env.DB_PASSWORD,
  {
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    dialect: process.env.DB_DIALECT || 'mysql',
    benchmark: true,
    logging: (sql, durationMs) => {
      const operation = getQueryOperation(sql);

      if (typeof durationMs === 'number') {
        databaseQueryDuration.observe({ operation }, durationMs / 1000);
      }

      if (process.env.DB_QUERY_LOGGING === 'true') {
        logger.debug('db_query', {
          operation,
          duration_ms: durationMs,
          sql: sql?.slice(0, 400)
        });
      }
    },
    pool: {
      max: 10,
      min: 0,
      acquire: 30000,
      idle: 10000
    },
    define: {
      timestamps: true,
      underscored: true,
      freezeTableName: true
    }
  }
);

export const testConnection = async () => {
  try {
    await sequelize.authenticate();
    logger.info('db_connection_established');
    
    // Test with a simple query
    const [results] = await sequelize.query('SELECT 1');
    logger.info('db_connection_test_successful', { results });
    
    return true;
  } catch (error) {
    logger.error('db_connection_failed', { error: error.message });
    return false;
  }
};

export { sequelize };
