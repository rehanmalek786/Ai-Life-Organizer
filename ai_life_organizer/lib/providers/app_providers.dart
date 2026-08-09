import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _ready = false;

  AuthProvider() {
    _authService.authStateChanges.listen((u) {
      _user = u;
      _ready = true;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isSignedIn => _user != null;
  bool get ready => _ready;

  Future<String?> signIn(String email, String password) => _authService.signIn(email, password);
  Future<String?> signUp(String email, String password, String name) =>
      _authService.signUp(email, password, name);
  Future<void> signOut() => _authService.signOut();
  Future<String?> resetPassword(String email) => _authService.sendPasswordReset(email);
}

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == 'light') _mode = ThemeMode.light;
    if (saved == 'dark') _mode = ThemeMode.dark;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final value = mode == ThemeMode.light ? 'light' : (mode == ThemeMode.dark ? 'dark' : 'system');
    await prefs.setString(_key, value);
  }
}
