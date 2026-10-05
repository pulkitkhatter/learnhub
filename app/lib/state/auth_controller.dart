import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/repository.dart';
import '../models/user.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthController extends ChangeNotifier {
  AuthController(this._api, this._repo, this._prefs) {
    _api.onUnauthorized = _expire;
  }

  static const _tokenKey = 'auth_token';

  final ApiClient _api;
  final LearnRepository _repo;
  final SharedPreferences _prefs;

  AuthStatus status = AuthStatus.unknown;
  User? user;

  /// Restores a saved session so users stay signed in across refreshes.
  Future<void> restore() async {
    final saved = _prefs.getString(_tokenKey);
    if (saved == null) return _set(AuthStatus.signedOut);
    _api.token = saved;
    try {
      user = await _repo.me();
      _set(AuthStatus.signedIn);
    } on ApiException catch (e) {
      // Only drop the session if the server actually rejected it. On a network
      // error stay signed in so the app can show a retryable error state.
      if (e.isUnauthorized) {
        await _clear();
      } else {
        _set(AuthStatus.signedIn);
      }
    }
  }

  Future<void> login(String email, String password) async =>
      _accept(await _repo.login(email.trim(), password));

  Future<void> register(String name, String email, String password) async =>
      _accept(await _repo.register(name.trim(), email.trim(), password));

  Future<void> logout() => _clear();

  Future<void> _accept(AuthResult result) async {
    _api.token = result.token;
    user = result.user;
    await _prefs.setString(_tokenKey, result.token);
    _set(AuthStatus.signedIn);
  }

  Future<void> _clear() async {
    _api.token = null;
    user = null;
    await _prefs.remove(_tokenKey);
    _set(AuthStatus.signedOut);
  }

  void _expire() {
    if (status == AuthStatus.signedIn) _clear();
  }

  void _set(AuthStatus s) {
    status = s;
    notifyListeners();
  }
}
