import { describe, it } from 'node:test';
import assert from 'node:assert';
import request from 'supertest';
import app from '../src/app.js';

describe('Books API', () => {
  it('should return all books', async () => {
    const res = await request(app).get('/api/v1/books');

    assert.strictEqual(res.statusCode, 200);
  });
});
