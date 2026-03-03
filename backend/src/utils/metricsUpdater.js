import { User } from '../models/index.js';
import { totalPlayers } from './metrics.js';
import { logger } from '../observability/logger.js';

export async function updatePlayerCount() {
  try {
    const count = await User.count();
    totalPlayers.set(count);
  } catch (error) {
    logger.error('player_count_metric_update_failed', { error: error.message });
  }
}

export function startMetricsUpdater() {
  // Update immediately on start
  updatePlayerCount();
  
  // Update every 5 minutes
  const interval = setInterval(updatePlayerCount, 5 * 60 * 1000);
  
  // Return interval ID in case you need to clear it later
  return interval;
}
