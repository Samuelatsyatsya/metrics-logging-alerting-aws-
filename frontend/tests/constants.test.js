import test from 'node:test';
import assert from 'node:assert/strict';

import {
  GAME_CHOICES,
  GAME_RESULTS,
  CHOICE_CONFIG,
  RESULT_CONFIG
} from '../src/utils/constants.js';

test('GAME_CHOICES contains expected values', () => {
  assert.deepEqual(Object.values(GAME_CHOICES).sort(), ['paper', 'rock', 'scissors']);
});

test('GAME_RESULTS contains expected values', () => {
  assert.deepEqual(Object.values(GAME_RESULTS).sort(), ['draw', 'lose', 'win']);
});

test('CHOICE_CONFIG defines rock-paper-scissors relationships', () => {
  assert.equal(CHOICE_CONFIG.rock.beats, GAME_CHOICES.SCISSORS);
  assert.equal(CHOICE_CONFIG.paper.beats, GAME_CHOICES.ROCK);
  assert.equal(CHOICE_CONFIG.scissors.beats, GAME_CHOICES.PAPER);
});

test('RESULT_CONFIG defines user-facing messages', () => {
  assert.equal(RESULT_CONFIG.win.message, 'You Win!');
  assert.equal(RESULT_CONFIG.lose.message, 'You Lose');
  assert.equal(RESULT_CONFIG.draw.message, "It's a Draw");
});
