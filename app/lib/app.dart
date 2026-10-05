import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'screens/course_detail_screen.dart';
import 'screens/course_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/quiz_screen.dart';
import 'state/auth_controller.dart';
import 'state/courses_controller.dart';
import 'state/theme_controller.dart';

class LearnHubApp extends StatefulWidget {
  const LearnHubApp({super.key});

  @override
  State<LearnHubApp> createState() => _LearnHubAppState();
}

class _LearnHubAppState extends State<LearnHubApp> {
  late final AuthController _auth = context.read<AuthController>();
  late final CoursesController _courses = context.read<CoursesController>();
  AuthStatus? _lastStatus;

  late final GoRouter _router = GoRouter(
    refreshListenable: _auth,
    redirect: (context, state) {
      final status = _auth.status;
      final atLogin = state.matchedLocation == '/login';
      final atSplash = state.matchedLocation == '/splash';
      // While the saved session is being verified, park on a splash screen but
      // remember the requested URL so deep links survive a refresh.
      if (status == AuthStatus.unknown) {
        return atSplash ? null : '/splash?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (status == AuthStatus.signedOut) return atLogin ? null : '/login';
      if (atLogin || atSplash) return state.uri.queryParameters['from'] ?? '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const Scaffold(body: Center(child: CircularProgressIndicator()))),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/', builder: (_, _) => const CourseListScreen()),
      GoRoute(
        path: '/course/:id',
        builder: (_, s) => CourseDetailScreen(courseId: s.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'quiz',
            builder: (_, s) => QuizScreen(courseId: s.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuthChanged);
    _auth.restore();
  }

  // Load data whenever a user signs in (including session restore).
  void _onAuthChanged() {
    if (_auth.status == _lastStatus) return;
    _lastStatus = _auth.status;
    if (_auth.status == AuthStatus.signedIn) _courses.load();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    return MaterialApp.router(
      title: 'LearnHub',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: theme.mode,
      routerConfig: _router,
    );
  }
}
