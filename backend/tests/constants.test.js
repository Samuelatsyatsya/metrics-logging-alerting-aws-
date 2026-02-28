import test from 'node:test';
import assert from 'node:assert/strict';

import { GAME_CHOICES, GAME_RESULTS, HTTP_STATUS } from '../src/config/constants.js';

test('GAME_CHOICES exposes rock, paper, scissors', () => {
  assert.deepEqual(Object.values(GAME_CHOICES).sort(), ['paper', 'rock', 'scissors']);
});

test('GAME_RESULTS exposes win, lose, draw', () => {
  assert.deepEqual(Object.values(GAME_RESULTS).sort(), ['draw', 'lose', 'win']);
});

test('HTTP_STATUS includes common API status codes', () => {
  assert.equal(HTTP_STATUS.OK, 200);
  assert.equal(HTTP_STATUS.BAD_REQUEST, 400);
  assert.equal(HTTP_STATUS.CONFLICT, 409);
  assert.equal(HTTP_STATUS.INTERNAL_SERVER_ERROR, 500);
});
