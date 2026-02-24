import client from 'prom-client';

// Create a Registry
const register = new client.Registry();

// Add default metrics (CPU, memory, event loop lag, etc.)
client.collectDefaultMetrics({ register });

// Custom metrics for the game
const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5]
});

const httpRequestTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const gameRoundsTotal = new client.Counter({
  name: 'game_rounds_total',
  help: 'Total number of game rounds played',
  labelNames: ['result'] // 'win', 'lose', 'draw'
});

const gameChoicesTotal = new client.Counter({
  name: 'game_choices_total',
  help: 'Total number of each choice made',
  labelNames: ['choice'] // 'rock', 'paper', 'scissors'
});

const activeGames = new client.Gauge({
  name: 'active_games',
  help: 'Number of currently active games'
});

const gameDuration = new client.Histogram({
  name: 'game_session_duration_seconds',
  help: 'Duration of game sessions in seconds',
  buckets: [1, 5, 10, 30, 60, 120, 300]
});

const totalPlayers = new client.Gauge({
  name: 'total_players',
  help: 'Total number of registered players'
});

const newPlayersTotal = new client.Counter({
  name: 'new_players_total',
  help: 'Total number of new players registered'
});

const databaseQueryDuration = new client.Histogram({
  name: 'database_query_duration_seconds',
  help: 'Duration of database queries',
  labelNames: ['operation'],
  buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1]
});

// Register custom metrics
register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestTotal);
register.registerMetric(gameRoundsTotal);
register.registerMetric(gameChoicesTotal);
register.registerMetric(activeGames);
register.registerMetric(gameDuration);
register.registerMetric(totalPlayers);
register.registerMetric(newPlayersTotal);
register.registerMetric(databaseQueryDuration);

export {
  register,
  httpRequestDuration,
  httpRequestTotal,
  gameRoundsTotal,
  gameChoicesTotal,
  activeGames,
  gameDuration,
  totalPlayers,
  newPlayersTotal,
  databaseQueryDuration
};
