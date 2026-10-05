const test = require('node:test');
const assert = require('node:assert');
const os = require('os');
const path = require('path');

process.env.DB_FILE = path.join(os.tmpdir(), `learnhub-test-${Date.now()}.json`);
const app = require('../src/app');

let base;
let server;
test.before(() => new Promise((r) => { server = app.listen(0, () => { base = `http://localhost:${server.address().port}`; r(); }); }));
test.after(() => server.close());

const call = async (method, url, body, token) => {
  const res = await fetch(base + url, {
    method,
    headers: { 'content-type': 'application/json', ...(token && { authorization: `Bearer ${token}` }) },
    body: body && JSON.stringify(body),
  });
  return { status: res.status, body: await res.json() };
};

test('courses list & quiz hides answers', async () => {
  const list = await call('GET', '/api/courses');
  assert.equal(list.status, 200);
  assert.ok(list.body.length >= 5);
  const quiz = await call('GET', `/api/courses/${list.body[0].id}/quiz`);
  assert.ok(quiz.body.questions.every((q) => q.answer === undefined && q.options.length > 1));
});

test('auth, progress and quiz flow', async () => {
  assert.equal((await call('GET', '/api/progress')).status, 401);
  const reg = await call('POST', '/api/auth/register', { name: 'Test', email: 'T@x.io', password: 'secret1' });
  assert.equal(reg.status, 201);
  assert.equal((await call('POST', '/api/auth/register', { name: 'Test', email: 't@x.io', password: 'secret1' })).status, 409);
  assert.equal((await call('POST', '/api/auth/login', { email: 't@x.io', password: 'bad' })).status, 401);
  const token = (await call('POST', '/api/auth/login', { email: 't@x.io', password: 'secret1' })).body.token;

  let p = (await call('PUT', '/api/courses/flutter-basics/lessons/widgets', { completed: true }, token)).body;
  assert.equal(p.courses['flutter-basics'].completed, 1);
  assert.equal(p.overall.completed, 1);
  p = (await call('PUT', '/api/courses/flutter-basics/completion', { completed: true }, token)).body;
  assert.equal(p.courses['flutter-basics'].completed, p.courses['flutter-basics'].total);
  p = (await call('PUT', '/api/courses/flutter-basics/completion', { completed: false }, token)).body;
  assert.equal(p.overall.completed, 0);

  const bad = await call('POST', '/api/courses/flutter-basics/quiz/submit', { answers: [0] }, token);
  assert.equal(bad.status, 400);
  const ok = await call('POST', '/api/courses/flutter-basics/quiz/submit', { answers: [0, 1, 1, 2, 1, null], durationSeconds: 42 }, token);
  assert.equal(ok.status, 201);
  assert.equal(ok.body.score, 5);
  assert.equal(ok.body.review[5].selectedIndex, null);
  assert.equal(ok.body.review[5].isCorrect, false);
  assert.equal((await call('GET', '/api/progress', null, token)).body.bestScores['flutter-basics'], 5);
});
