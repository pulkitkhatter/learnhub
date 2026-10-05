// Seed course catalogue. Quiz `answer` is the index of the correct option and
// is never sent to the client until a quiz is submitted.

const q = (question, options, answer, explanation) => ({ question, options, answer, explanation });

module.exports = [
  {
    id: 'flutter-basics',
    title: 'Flutter Fundamentals',
    emoji: '🦋',
    level: 'Beginner',
    durationMinutes: 90,
    summary: 'Build beautiful cross-platform UIs with widgets, layouts and state.',
    description:
      'Learn how Flutter renders UI from a tree of widgets, how to compose layouts, and how to manage state so your app stays fast and predictable.',
    lessons: [
      {
        id: 'widgets',
        title: 'Everything is a widget',
        minutes: 15,
        content:
          'In Flutter, UI is described by an immutable tree of widgets. A widget is a lightweight description of part of the screen; Flutter diffs the new tree against the old one and updates only what changed.\n\nStatelessWidgets describe UI that depends only on their configuration. StatefulWidgets own a State object that survives rebuilds and can call setState to schedule a rebuild.\n\nKey idea: build() should be cheap and free of side effects — Flutter may call it many times per second.',
      },
      {
        id: 'layout',
        title: 'Layouts with Row, Column & Stack',
        minutes: 25,
        content:
          'Row and Column lay children out along the main axis; Expanded and Flexible share leftover space. Stack overlaps children and Positioned places them.\n\nFlutter layout follows one rule: constraints go down, sizes go up, parents set position. Understanding this rule explains almost every "overflow" error.\n\nUse LayoutBuilder or MediaQuery to adapt between mobile and desktop widths.',
      },
      {
        id: 'state',
        title: 'State management basics',
        minutes: 30,
        content:
          'Local state lives in a StatefulWidget. Shared state should be lifted up and exposed to descendants, e.g. via InheritedWidget, Provider or Riverpod.\n\nPrefer small notifiers (ChangeNotifier / ValueNotifier) that expose immutable data and methods. Widgets listen and rebuild only when the data they use changes.\n\nSeparate UI from business logic so each piece can be tested on its own.',
      },
      {
        id: 'navigation',
        title: 'Navigation & routing',
        minutes: 20,
        content:
          'Navigator manages a stack of routes: push adds a screen, pop removes it. Named routes and the Router API (go_router) give you deep links and browser URL support on the web.\n\nPass data through route arguments or path parameters, and keep route names in one place to avoid typos.',
      },
    ],
    quiz: {
      timeLimitSeconds: 150,
      questions: [
        q('What does Flutter use to describe the UI?', ['A tree of widgets', 'XML layout files', 'HTML templates', 'Native views only'], 0, 'Flutter UIs are declared as an immutable widget tree.'),
        q('Which widget owns mutable state that survives rebuilds?', ['StatelessWidget', 'StatefulWidget', 'Container', 'Text'], 1, 'StatefulWidget creates a State object that lives across rebuilds.'),
        q('Which layout rule does Flutter follow?', ['Sizes go down, constraints go up', 'Constraints go down, sizes go up', 'Children position parents', 'Everything is absolutely positioned'], 1, 'Constraints go down, sizes go up, parent sets position.'),
        q('Which widget stacks children on top of each other?', ['Column', 'Row', 'Stack', 'ListView'], 2, 'Stack overlaps its children.'),
        q('What triggers a rebuild of a StatefulWidget?', ['Calling print()', 'Calling setState()', 'Hot restarting only', 'Changing a local variable'], 1, 'setState marks the State dirty so build runs again.'),
        q('Which is a good way to adapt to screen width?', ['LayoutBuilder', 'A fixed pixel width', 'Ignoring it', 'Using only Row'], 0, 'LayoutBuilder exposes the parent constraints.'),
      ],
    },
  },
  {
    id: 'dart-language',
    title: 'Dart Language Essentials',
    emoji: '🎯',
    level: 'Beginner',
    durationMinutes: 75,
    summary: 'Master types, null safety, collections and async programming in Dart.',
    description:
      'Dart is the language behind Flutter. This course covers the type system, sound null safety, collections and futures so you can write idiomatic, bug-resistant code.',
    lessons: [
      {
        id: 'types',
        title: 'Variables & types',
        minutes: 15,
        content:
          'Dart is statically typed with type inference. Use var, final (assigned once) and const (compile-time constant).\n\nCore types: int, double, String, bool, List, Set and Map. String interpolation uses $name or ${expression}.',
      },
      {
        id: 'null-safety',
        title: 'Sound null safety',
        minutes: 20,
        content:
          'Types are non-nullable by default. Add ? to allow null (String?). Use ?. for safe access, ?? for defaults and ! only when you are certain a value is not null.\n\nThe compiler promotes nullable variables to non-null after a null check, which removes whole classes of runtime errors.',
      },
      {
        id: 'collections',
        title: 'Collections & functional style',
        minutes: 20,
        content:
          'Lists, sets and maps support map, where, fold and any/every. Collection-if and collection-for let you build lists declaratively inside UI code.\n\nPrefer immutable collections (List.unmodifiable, const) for data that should not change.',
      },
      {
        id: 'async',
        title: 'Futures & async/await',
        minutes: 20,
        content:
          'A Future represents a value that will arrive later. async functions return Futures and await pauses until one completes without blocking the UI.\n\nHandle failures with try/catch around await. Streams model many values over time.',
      },
    ],
    quiz: {
      timeLimitSeconds: 120,
      questions: [
        q('Which keyword declares a compile-time constant?', ['final', 'const', 'var', 'static'], 1, 'const values are fixed at compile time.'),
        q('How do you declare a nullable String?', ['String!', 'String?', 'nullable String', 'String*'], 1, 'Append ? to the type.'),
        q('What does the ?? operator do?', ['Throws if null', 'Returns the right side if left is null', 'Casts to non-null', 'Compares types'], 1, 'a ?? b yields b when a is null.'),
        q('What does an async function return?', ['void', 'A Future', 'A Stream always', 'A List'], 1, 'async functions wrap their result in a Future.'),
        q('Which method transforms every element of a list?', ['where', 'map', 'any', 'skip'], 1, 'map applies a function to every element.'),
      ],
    },
  },
  {
    id: 'web-fundamentals',
    title: 'Web Fundamentals',
    emoji: '🌐',
    level: 'Beginner',
    durationMinutes: 80,
    summary: 'HTML, CSS and JavaScript — the three pillars of the web.',
    description:
      'Understand how browsers turn HTML, CSS and JavaScript into the pages you use every day, and learn the responsive-design habits that make sites work on any screen.',
    lessons: [
      {
        id: 'html',
        title: 'Semantic HTML',
        minutes: 15,
        content:
          'HTML gives a page its structure. Use semantic elements — header, nav, main, article, footer — so browsers, search engines and screen readers understand your content.\n\nEvery image needs an alt attribute, and every form control needs a label.',
      },
      {
        id: 'css',
        title: 'CSS & the box model',
        minutes: 25,
        content:
          'Every element is a box: content, padding, border, margin. box-sizing: border-box makes widths include padding and border.\n\nFlexbox lays out items in one dimension, Grid in two. Custom properties (--color) make theming and dark mode simple.',
      },
      {
        id: 'responsive',
        title: 'Responsive design',
        minutes: 20,
        content:
          'Start mobile-first and add media queries as the viewport grows. Use relative units (rem, %, vw) and flexible grids rather than fixed pixels.\n\nAlways include <meta name="viewport" content="width=device-width, initial-scale=1">.',
      },
      {
        id: 'js',
        title: 'JavaScript & the DOM',
        minutes: 20,
        content:
          'JavaScript adds behaviour. The DOM is a live tree of the page; querySelector finds nodes and addEventListener reacts to user input.\n\nfetch() requests data over HTTP and returns a Promise; combine it with async/await for readable asynchronous code.',
      },
    ],
    quiz: {
      timeLimitSeconds: 120,
      questions: [
        q('Which element should hold the main navigation links?', ['<div>', '<nav>', '<span>', '<section>'], 1, '<nav> is the semantic element for navigation.'),
        q('What does box-sizing: border-box change?', ['Width includes padding and border', 'Adds a border', 'Hides overflow', 'Removes margins'], 0, 'With border-box, padding and border are inside the declared width.'),
        q('Which CSS feature lays items out in two dimensions?', ['Flexbox', 'Grid', 'Float', 'Inline'], 1, 'CSS Grid handles rows and columns.'),
        q('Which API fetches data over HTTP in the browser?', ['fetch()', 'print()', 'require()', 'open()'], 0, 'fetch returns a Promise for the response.'),
        q('Mobile-first design means…', ['Designing for desktop first', 'Starting with small screens and scaling up', 'Only supporting phones', 'Using fixed widths'], 1, 'Base styles target small screens; media queries add enhancements.'),
      ],
    },
  },
  {
    id: 'git-github',
    title: 'Git & GitHub Workflow',
    emoji: '🌿',
    level: 'Intermediate',
    durationMinutes: 60,
    summary: 'Version control, branching and collaboration like a professional.',
    description:
      'Git tracks every change to your code. Learn the everyday commands, how branching enables safe experiments, and how pull requests keep teams in sync.',
    lessons: [
      {
        id: 'basics',
        title: 'Commits & the staging area',
        minutes: 15,
        content:
          'git add stages changes and git commit records a snapshot with a message. Write commits that do one thing, with a message that explains why.\n\ngit status and git diff show what is changed; git log shows history.',
      },
      {
        id: 'branches',
        title: 'Branching & merging',
        minutes: 15,
        content:
          'A branch is a movable pointer to a commit. Create one per feature with git switch -c feature-name.\n\nMerge combines histories; rebase replays your commits on top of another branch for a linear history. Never rebase commits that others have already pulled.',
      },
      {
        id: 'remotes',
        title: 'Remotes & pull requests',
        minutes: 15,
        content:
          'A remote such as GitHub hosts a shared copy. git push uploads commits and git pull fetches and merges updates.\n\nA pull request proposes merging a branch, enabling review, discussion and automated checks before the code lands.',
      },
      {
        id: 'conflicts',
        title: 'Resolving conflicts',
        minutes: 15,
        content:
          'Conflicts occur when two branches change the same lines. Git marks them with <<<<<<<, ======= and >>>>>>>.\n\nEdit the file to the desired result, git add it, then continue the merge or rebase.',
      },
    ],
    quiz: {
      timeLimitSeconds: 90,
      questions: [
        q('Which command stages all changes in the current directory?', ['git add .', 'git push', 'git stage-all', 'git fetch'], 0, 'git add . stages the working directory changes.'),
        q('What is a branch in Git?', ['A copy of the whole repo', 'A movable pointer to a commit', 'A remote server', 'A tag only'], 1, 'Branches are lightweight pointers.'),
        q('What is a pull request for?', ['Deleting a repo', 'Proposing and reviewing changes before merging', 'Downloading files', 'Creating a remote'], 1, 'PRs enable review and checks before merge.'),
        q('When do merge conflicts happen?', ['Branches change the same lines', 'You commit too often', 'You use rebase', 'The repo is public'], 0, 'Git cannot auto-combine overlapping edits.'),
      ],
    },
  },
  {
    id: 'rest-apis',
    title: 'REST APIs with Node.js',
    emoji: '🚀',
    level: 'Intermediate',
    durationMinutes: 100,
    summary: 'Design and build secure JSON APIs with Express and JWT.',
    description:
      'Design resource-oriented HTTP APIs, implement them with Express, and protect them with token-based authentication.',
    lessons: [
      {
        id: 'http',
        title: 'HTTP & REST principles',
        minutes: 20,
        content:
          'REST models your domain as resources addressed by URLs and manipulated with HTTP verbs: GET reads, POST creates, PUT/PATCH updates and DELETE removes.\n\nStatus codes communicate outcomes: 200 OK, 201 Created, 400 Bad Request, 401 Unauthorized, 404 Not Found, 500 Server Error.',
      },
      {
        id: 'express',
        title: 'Building with Express',
        minutes: 30,
        content:
          'Express routes map a method and path to a handler. Middleware are functions that run before handlers — use them for JSON parsing, logging, CORS and authentication.\n\nKeep routes thin: validate input, call a service, return JSON.',
      },
      {
        id: 'auth',
        title: 'Authentication with JWT',
        minutes: 30,
        content:
          'Hash passwords with bcrypt — never store them in plain text. After login, issue a signed JSON Web Token and require it in the Authorization: Bearer header.\n\nA JWT is signed, not encrypted: do not put secrets inside it, and give it an expiry.',
      },
      {
        id: 'errors',
        title: 'Error handling & validation',
        minutes: 20,
        content:
          'Validate every input at the boundary and return clear 4xx errors with a consistent JSON shape, e.g. { "error": "message" }.\n\nA central error-handling middleware prevents leaking stack traces and keeps handlers simple.',
      },
    ],
    quiz: {
      timeLimitSeconds: 150,
      questions: [
        q('Which HTTP verb is used to create a resource?', ['GET', 'POST', 'DELETE', 'HEAD'], 1, 'POST creates new resources.'),
        q('Which status code means "Unauthorized"?', ['200', '404', '401', '500'], 2, '401 means missing or invalid credentials.'),
        q('How should passwords be stored?', ['Plain text', 'Base64', 'Hashed with bcrypt', 'In the JWT'], 2, 'Always store a salted hash.'),
        q('What is Express middleware?', ['A database', 'A function that runs before route handlers', 'A CSS tool', 'A test runner'], 1, 'Middleware can modify requests or end them early.'),
        q('Is a JWT encrypted by default?', ['Yes, always', 'No, it is only signed', 'Only on HTTPS', 'Only with bcrypt'], 1, 'The payload is base64 encoded and readable.'),
        q('Where is a Bearer token sent?', ['URL fragment', 'Authorization header', 'Response body', 'HTML title'], 1, 'Authorization: Bearer <token>.'),
      ],
    },
  },
];
