const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const app = require('./app');
const store = require('./store');

// Demo account so the app can be tried instantly (see login screen).
if (!store.findUserByEmail('demo@learnhub.dev')) {
  store.addUser({
    id: crypto.randomUUID(),
    name: 'Demo Learner',
    email: 'demo@learnhub.dev',
    passwordHash: bcrypt.hashSync('demo1234', 10),
  });
}

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => console.log(`LearnHub running on http://localhost:${PORT}`));
