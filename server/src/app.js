const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const path = require('path');
const fs = require('fs');
const courses = require('./data/courses');
const store = require('./store');

const JWT_SECRET = process.env.JWT_SECRET || 'dev-only-secret-change-me';
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const app = express();
app.use(cors());
app.use(express.json());

// ---------- helpers ----------
class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

const publicUser = (u) => ({ id: u.id, name: u.name, email: u.email });
const signToken = (u) => jwt.sign({ sub: u.id }, JWT_SECRET, { expiresIn: '7d' });

const findCourse = (id) => {
  const course = courses.find((c) => c.id === id);
  if (!course) throw new HttpError(404, 'Course not found');
  return course;
};

const summarize = (c) => ({
  id: c.id,
  title: c.title,
  emoji: c.emoji,
  level: c.level,
  summary: c.summary,
  durationMinutes: c.durationMinutes,
  lessonCount: c.lessons.length,
  questionCount: c.quiz.questions.length,
});

const detail = (c) => ({
  ...summarize(c),
  description: c.description,
  lessons: c.lessons,
  quiz: { timeLimitSeconds: c.quiz.timeLimitSeconds, questionCount: c.quiz.questions.length },
});

function requireAuth(req, _res, next) {
  const header = req.get('authorization') || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return next(new HttpError(401, 'Authentication required'));
  try {
    const user = store.findUserById(jwt.verify(token, JWT_SECRET).sub);
    if (!user) throw new Error('unknown user');
    req.user = user;
    next();
  } catch (_) {
    next(new HttpError(401, 'Invalid or expired token'));
  }
}

const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

// ---------- auth ----------
app.post('/api/auth/register', wrap(async (req, res) => {
  const { name, email, password } = req.body || {};
  if (!name || String(name).trim().length < 2) throw new HttpError(400, 'Name must be at least 2 characters');
  if (!EMAIL_RE.test(email || '')) throw new HttpError(400, 'Enter a valid email address');
  if (!password || String(password).length < 6) throw new HttpError(400, 'Password must be at least 6 characters');
  const normalized = String(email).trim().toLowerCase();
  if (store.findUserByEmail(normalized)) throw new HttpError(409, 'An account with this email already exists');
  const user = store.addUser({
    id: crypto.randomUUID(),
    name: String(name).trim(),
    email: normalized,
    passwordHash: await bcrypt.hash(String(password), 10),
  });
  res.status(201).json({ token: signToken(user), user: publicUser(user) });
}));

app.post('/api/auth/login', wrap(async (req, res) => {
  const { email, password } = req.body || {};
  const user = store.findUserByEmail(String(email || '').trim().toLowerCase());
  if (!user || !(await bcrypt.compare(String(password || ''), user.passwordHash))) {
    throw new HttpError(401, 'Incorrect email or password');
  }
  res.json({ token: signToken(user), user: publicUser(user) });
}));

app.get('/api/auth/me', requireAuth, (req, res) => res.json({ user: publicUser(req.user) }));

// ---------- courses ----------
app.get('/api/courses', (_req, res) => res.json(courses.map(summarize)));
app.get('/api/courses/:id', (req, res) => res.json(detail(findCourse(req.params.id))));

// Quiz questions are served WITHOUT answers; grading happens on submit.
app.get('/api/courses/:id/quiz', (req, res) => {
  const { quiz } = findCourse(req.params.id);
  res.json({
    timeLimitSeconds: quiz.timeLimitSeconds,
    questions: quiz.questions.map(({ question, options }) => ({ question, options })),
  });
});

// ---------- progress ----------
const progressPayload = (userId) => {
  const done = store.getProgress(userId);
  const byCourse = {};
  let completed = 0;
  let total = 0;
  for (const c of courses) {
    const ids = (done[c.id] || []).filter((id) => c.lessons.some((l) => l.id === id));
    byCourse[c.id] = { completedLessonIds: ids, completed: ids.length, total: c.lessons.length };
    completed += ids.length;
    total += c.lessons.length;
  }
  const best = {};
  for (const r of store.getQuizResults(userId)) {
    best[r.courseId] = Math.max(best[r.courseId] || 0, r.score);
  }
  return { courses: byCourse, overall: { completed, total }, bestScores: best };
};

app.get('/api/progress', requireAuth, (req, res) => res.json(progressPayload(req.user.id)));

// Mark / un-mark a single lesson.
app.put('/api/courses/:id/lessons/:lessonId', requireAuth, (req, res) => {
  const course = findCourse(req.params.id);
  if (!course.lessons.some((l) => l.id === req.params.lessonId)) throw new HttpError(404, 'Lesson not found');
  if (typeof req.body?.completed !== 'boolean') throw new HttpError(400, '"completed" must be a boolean');
  const set = new Set(store.getProgress(req.user.id)[course.id] || []);
  req.body.completed ? set.add(req.params.lessonId) : set.delete(req.params.lessonId);
  store.setCompletedLessons(req.user.id, course.id, [...set]);
  res.json(progressPayload(req.user.id));
});

// Mark / un-mark the entire course.
app.put('/api/courses/:id/completion', requireAuth, (req, res) => {
  const course = findCourse(req.params.id);
  if (typeof req.body?.completed !== 'boolean') throw new HttpError(400, '"completed" must be a boolean');
  store.setCompletedLessons(req.user.id, course.id, req.body.completed ? course.lessons.map((l) => l.id) : []);
  res.json(progressPayload(req.user.id));
});

// ---------- quiz results ----------
app.post('/api/courses/:id/quiz/submit', requireAuth, (req, res) => {
  const course = findCourse(req.params.id);
  const { answers, durationSeconds } = req.body || {};
  const questions = course.quiz.questions;
  if (!Array.isArray(answers) || answers.length !== questions.length) {
    throw new HttpError(400, `"answers" must be an array of ${questions.length} entries (null for unanswered)`);
  }
  const review = questions.map((qn, i) => {
    const selected = Number.isInteger(answers[i]) && answers[i] >= 0 && answers[i] < qn.options.length ? answers[i] : null;
    return {
      question: qn.question,
      options: qn.options,
      selectedIndex: selected,
      correctIndex: qn.answer,
      isCorrect: selected === qn.answer,
      explanation: qn.explanation,
    };
  });
  const score = review.filter((r) => r.isCorrect).length;
  const result = store.addQuizResult({
    id: crypto.randomUUID(),
    userId: req.user.id,
    courseId: course.id,
    score,
    total: questions.length,
    durationSeconds: Math.max(0, Math.min(Number(durationSeconds) || 0, 24 * 3600)),
    takenAt: new Date().toISOString(),
  });
  res.status(201).json({
    score,
    total: questions.length,
    durationSeconds: result.durationSeconds,
    review,
    bestScore: Math.max(...store.getQuizResults(req.user.id, course.id).map((r) => r.score)),
  });
});

app.get('/api/courses/:id/quiz/results', requireAuth, (req, res) => {
  findCourse(req.params.id);
  res.json(store.getQuizResults(req.user.id, req.params.id).slice(-10).reverse());
});

// ---------- optional: serve the built Flutter web app ----------
const webRoot = path.join(__dirname, '..', '..', 'app', 'build', 'web');
if (fs.existsSync(webRoot)) {
  app.use(express.static(webRoot));
  app.get(/^\/(?!api\/).*/, (_req, res) => res.sendFile(path.join(webRoot, 'index.html')));
}

// ---------- errors ----------
app.use('/api', (_req, _res, next) => next(new HttpError(404, 'Not found')));
// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  if (err.type === 'entity.parse.failed') return res.status(400).json({ error: 'Invalid JSON body' });
  const status = err.status || 500;
  if (status === 500) console.error(err);
  res.status(status).json({ error: status === 500 ? 'Internal server error' : err.message });
});

module.exports = app;
