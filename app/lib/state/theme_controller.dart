import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs)
      : mode = switch (_prefs.getString(_key)) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };

  static const _key = 'theme_mode';
  final SharedPreferences _prefs;
  ThemeMode mode;

  bool isDark(BuildContext context) =>
      mode == ThemeMode.dark ||
      (mode == ThemeMode.system &&
          MediaQuery.platformBrightnessOf(context) == Brightness.dark);

  void toggle(BuildContext context) {
    mode = isDark(context) ? ThemeMode.light : ThemeMode.dark;
    _prefs.setString(_key, mode.name);
    notifyListeners();
  }
}
