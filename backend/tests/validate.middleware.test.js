import test from 'node:test';
import assert from 'node:assert/strict';

import { validate } from '../src/middleware/validate.js';
import { submitGameValidation, usernameValidation } from '../src/validations/game.validations.js';

function createResponseDouble() {
  return {
    statusCode: undefined,
    payload: undefined,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(body) {
      this.payload = body;
      return this;
    }
  };
}

test('validate middleware calls next when body is valid', () => {
  const middleware = validate(submitGameValidation);
  const req = {
    body: {
      username: 'tester_01',
      result: 'draw',
      player_choice: 'rock',
      computer_choice: 'rock',
      session_duration: 5
    }
  };
  const res = createResponseDouble();

  let nextCalled = false;
  middleware(req, res, () => {
    nextCalled = true;
  });

  assert.equal(nextCalled, true);
  assert.equal(res.statusCode, undefined);
});

test('validate middleware responds with 400 when body is invalid', () => {
  const middleware = validate(submitGameValidation);
  const req = {
    body: {
      username: '',
      result: 'draw'
    }
  };
  const res = createResponseDouble();

  let nextCalled = false;
  middleware(req, res, () => {
    nextCalled = true;
  });

  assert.equal(nextCalled, false);
  assert.equal(res.statusCode, 400);
  assert.equal(res.payload.success, false);
  assert.equal(res.payload.message, 'Validation failed');
  assert.ok(Array.isArray(res.payload.errors));
  assert.ok(res.payload.errors.length > 0);
});

test('validate middleware validates params when source is params', () => {
  const middleware = validate(usernameValidation, 'params');
  const req = {
    body: {},
    params: {
      username: 'test_user'
    }
  };
  const res = createResponseDouble();

  let nextCalled = false;
  middleware(req, res, () => {
    nextCalled = true;
  });

  assert.equal(nextCalled, true);
  assert.equal(res.statusCode, undefined);
});
