const fs = require('fs');
const path = require('path');

// Tiny JSON-file persistence so progress survives restarts. Swap for a real DB
// by re-implementing these few functions.
const FILE = process.env.DB_FILE || path.join(__dirname, '..', 'db.json');

let db = { users: [], progress: {}, quizResults: [] };

function load() {
  try {
    db = { ...db, ...JSON.parse(fs.readFileSync(FILE, 'utf8')) };
  } catch (_) {
    /* first run */
  }
}

function save() {
  const tmp = `${FILE}.tmp`;
  fs.writeFileSync(tmp, JSON.stringify(db, null, 2));
  fs.renameSync(tmp, FILE);
}

load();

module.exports = {
  findUserByEmail: (email) => db.users.find((u) => u.email === email),
  findUserById: (id) => db.users.find((u) => u.id === id),
  addUser(user) {
    db.users.push(user);
    save();
    return user;
  },
  // progress[userId][courseId] = [lessonId, ...]
  getProgress: (userId) => db.progress[userId] || {},
  setCompletedLessons(userId, courseId, lessonIds) {
    db.progress[userId] = { ...(db.progress[userId] || {}), [courseId]: lessonIds };
    save();
  },
  addQuizResult(result) {
    db.quizResults.push(result);
    save();
    return result;
  },
  getQuizResults: (userId, courseId) =>
    db.quizResults.filter((r) => r.userId === userId && (!courseId || r.courseId === courseId)),
};
