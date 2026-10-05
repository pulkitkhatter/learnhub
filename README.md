# LearnHub

A course-learning web app: browse courses, read lessons, mark them complete with live progress, and take a timed quiz per course.

- **Frontend:** Flutter Web (`app/`) — Provider + go_router, Material 3
- **Backend:** Node.js + Express (`server/`) — JWT auth, JSON-file persistence

## Run it

```bash
# 1. Build the web app (once, or after changing Flutter code)
cd app && flutter pub get && flutter build web --release

# 2. Start the API (it also serves the built web app)
cd ../server && npm install && npm start
# → open http://localhost:4000
```

Click **“Try the demo account”** on the login screen, or register a new account.

Development with hot reload:

```bash
cd server && npm start                 # API on :4000
cd app && flutter run -d chrome        # uses http://localhost:4000/api by default
# point at another API:  --dart-define=API_URL=https://host/api
```

Tests: `cd server && npm test` · `cd app && flutter test`

## Assignment checklist

| Requirement | Where |
|---|---|
| **Course list** (5 courses from the API) | `screens/course_list_screen.dart`, `GET /api/courses` |
| **Course detail** — title, description, lesson content | `screens/course_detail_screen.dart`, `GET /api/courses/:id` |
| **Mark as completed** — per lesson *and* whole course | lesson / course buttons → `PUT /api/courses/:id/lessons/:lessonId`, `PUT /api/courses/:id/completion` |
| **Progress indicator** — per course and overall | progress bars/rings on cards, list header, and detail; animate on change; optimistic with rollback on failure |
| **Quiz: multiple choice** | questions fetched from `GET /api/courses/:id/quiz` (answers are *not* sent to the client) |
| **Quiz: timer** | countdown in `state/quiz_controller.dart`, turns red under 30 s, **auto-submits at 0:00** |
| **Quiz: next / previous** | Previous/Next buttons plus numbered jump dots; Finish on the last question (warns about unanswered) |
| **Quiz: result summary** | score, correct / incorrect counts, time taken, best score, per-question review with correct answer + explanation (server-graded via `POST /api/courses/:id/quiz/submit`) |
| **Quiz: retry** | “Retry quiz” on the result screen starts a fresh attempt |
| **Loading / empty / error states** | skeleton cards, spinner views, `ErrorView` with *Try again*, empty course list, empty search results, failed-submit recovery (answers are kept) |
| **Desktop + mobile layout** | 1/2/3-column grid, two-column detail on wide screens, stacked on phones |
| **Small backend** | `server/` — serves courses, stores progress and quiz results |
| **Authentication** | register / login with bcrypt-hashed passwords and 7-day JWT; session restored on refresh; 401 signs out |
| **Progress persists after refresh** | stored server-side per user; deep links (`/#/course/:id`) survive refresh |
| **Extras** | dark mode (persisted, follows system by default), hero / staggered / animated transitions, leave-quiz confirmation, search, pull-to-refresh |

## Structure

```
app/lib
  core/      api client, repository (all endpoints), theme, formatting
  models/    plain data classes with fromJson
  state/     ChangeNotifier controllers: auth, courses+progress, quiz, theme
  screens/   login, course list, course detail, quiz (intro/question/result)
  widgets/   course card, progress bar/ring, loading/empty/error views
server/src
  app.js     routes + validation + error handling (exported for tests)
  store.js   JSON-file persistence (swap for a DB by re-implementing 6 functions)
  data/      course catalogue + quiz questions
```

## Notes

- The demo user (`demo@learnhub.dev`) is seeded on server start. Set `JWT_SECRET` in any real deployment.
- Data lives in `server/db.json` (git-ignored); delete it to reset all users and progress.
