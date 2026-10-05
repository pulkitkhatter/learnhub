# LearnHub

A small course-learning app. You can browse courses, read the lessons, tick them off and watch your progress grow, then test yourself with a timed quiz for each course. Progress is saved to your account, so it's still there after a refresh.

The front end is Flutter Web and the back end is a simple Node/Express API.

## Running it

You'll need Flutter and Node installed.

```bash
cd app && flutter pub get && flutter build web --release
cd ../server && npm install && npm start
```

Then open http://localhost:4000. The server also serves the built app, so there's nothing else to start.

The login screen has a "Try the demo account" button (`demo@learnhub.dev` / `demo1234`), or you can just create your own account.

## Tests

```bash
cd server && npm test
cd app && flutter test
```

## Good to know

- Everything is stored in `server/db.json`. Delete that file to start fresh.
- If you deploy this anywhere real, set a `JWT_SECRET` environment variable.
