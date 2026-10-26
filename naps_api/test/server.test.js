const { after, test } = require('node:test');
const assert = require('node:assert/strict');

process.env.PORT = '4000';
process.env.MONGODB_URI = 'mongodb://127.0.0.1:27017/naps';
process.env.JWT_SECRET = 'test-secret-that-is-long-enough-for-local-tests';
process.env.BOOTSTRAP_SECRET = 'test-setup-secret';
process.env.CORS_ORIGIN = '*';

const { app } = require('../server');
const { createPasswordHash, passwordMatches } = require('../controllers/authController');
let server;
let apiAddress;

const startTestServer = async () => {
  if (server) return;
  server = app.listen(0, '127.0.0.1');
  await new Promise((resolve, reject) => {
    server.once('listening', resolve);
    server.once('error', reject);
  });
  apiAddress = `http://127.0.0.1:${server.address().port}`;
};

after(() => new Promise((resolve) => server ? server.close(resolve) : resolve()));

test('the API reports readiness without exposing database credentials', async () => {
  await startTestServer();
  const response = await fetch(`${apiAddress}/health`);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { status: 'ok' });
});

test('shared work routes require an authenticated session', async () => {
  await startTestServer();
  const response = await fetch(`${apiAddress}/api/tasks`);
  assert.equal(response.status, 401);
  assert.deepEqual(await response.json(), { message: 'please sign in to continue' });
});

test('organization setup rejects an incorrect setup secret', async () => {
  await startTestServer();
  const response = await fetch(`${apiAddress}/api/auth/bootstrap`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ setupSecret: 'incorrect' }),
  });
  assert.equal(response.status, 403);
  assert.deepEqual(await response.json(), { message: 'invalid organization setup code' });
});

test('password hashes use a unique salt and verify the original password', async () => {
  const firstHash = await createPasswordHash('a-long-test-password');
  const secondHash = await createPasswordHash('a-long-test-password');
  assert.notEqual(firstHash, secondHash);
  assert.equal(await passwordMatches('a-long-test-password', firstHash), true);
  assert.equal(await passwordMatches('incorrect-password', firstHash), false);
});
