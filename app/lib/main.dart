import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/api_client.dart';
import 'core/repository.dart';
import 'state/auth_controller.dart';
import 'state/courses_controller.dart';
import 'state/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final api = ApiClient();
  final repo = LearnRepository(api);

  runApp(MultiProvider(
    providers: [
      Provider<LearnRepository>.value(value: repo),
      ChangeNotifierProvider(create: (_) => ThemeController(prefs)),
      ChangeNotifierProvider(create: (_) => AuthController(api, repo, prefs)),
      ChangeNotifierProvider(create: (_) => CoursesController(repo)),
    ],
    child: const LearnHubApp(),
  ));
}
