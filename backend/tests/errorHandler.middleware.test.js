import test from 'node:test';
import assert from 'node:assert/strict';

import { errorHandler } from '../src/middleware/errorHandler.js';

function runErrorHandler(err) {
  let statusCode;
  let payload;
  const res = {
    status(code) {
      statusCode = code;
      return this;
    },
    json(body) {
      payload = body;
      return this;
    }
  };

  errorHandler(err, {}, res, () => {});
  return { statusCode, payload };
}

test('handles SequelizeValidationError as 400', () => {
  const err = {
    name: 'SequelizeValidationError',
    errors: [{ path: 'username', message: 'Username is required' }]
  };

  const { statusCode, payload } = runErrorHandler(err);
  assert.equal(statusCode, 400);
  assert.equal(payload.message, 'Validation error');
  assert.equal(payload.errors[0].field, 'username');
});

test('handles SequelizeUniqueConstraintError as 409', () => {
  const err = {
    name: 'SequelizeUniqueConstraintError',
    errors: [{ path: 'username' }]
  };

  const { statusCode, payload } = runErrorHandler(err);
  assert.equal(statusCode, 409);
  assert.equal(payload.message, 'Resource already exists');
  assert.equal(payload.field, 'username');
});

test('handles JsonWebTokenError as 401', () => {
  const err = { name: 'JsonWebTokenError' };

  const { statusCode, payload } = runErrorHandler(err);
  assert.equal(statusCode, 401);
  assert.equal(payload.message, 'Invalid token');
});

test('handles unknown error using statusCode/message fallback', () => {
  const err = { statusCode: 418, message: 'Teapot' };

  const { statusCode, payload } = runErrorHandler(err);
  assert.equal(statusCode, 418);
  assert.equal(payload.message, 'Teapot');
});
