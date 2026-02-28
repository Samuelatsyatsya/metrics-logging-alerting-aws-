import test from 'node:test';
import assert from 'node:assert/strict';

import { submitGameValidation, usernameValidation } from '../src/validations/game.validations.js';

const validPayload = {
  username: 'player_one',
  result: 'win',
  player_choice: 'rock',
  computer_choice: 'scissors',
  session_duration: 12
};

test('submitGameValidation accepts valid payload', () => {
  const { error, value } = submitGameValidation.validate(validPayload);
  assert.equal(error, undefined);
  assert.equal(value.username, 'player_one');
});

test('submitGameValidation rejects invalid username characters', () => {
  const { error } = submitGameValidation.validate({
    ...validPayload,
    username: 'bad user'
  });

  assert.ok(error);
  assert.match(error.details[0].message, /letters, numbers, and underscores/i);
});

test('submitGameValidation rejects unknown result value', () => {
  const { error } = submitGameValidation.validate({
    ...validPayload,
    result: 'victory'
  });

  assert.ok(error);
  assert.match(error.details[0].message, /must be one of/i);
});

test('usernameValidation enforces minimum length', () => {
  const { error } = usernameValidation.validate({ username: 'ab' });
  assert.ok(error);
});
