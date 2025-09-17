import 'package:flutter/foundation.dart';
import '../api/auth_api.dart';
import '../models/user.dart';
import '../core/token_storage.dart';

class AuthProvider with ChangeNotifier {
  final AuthApi _api;
  User? _user;
  String? _token;
  bool _loading = false;

  AuthProvider({AuthApi? api}) : _api = api ?? AuthApi();

  User? get user => _user;
  bool get isLoading => _loading;
  bool get isLoggedIn => _token != null;

  Future<void> loadSession() async {
    _token = await TokenStorage.read();
    if (_token != null) {
      try { _user = await _api.me(); } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> register(String email, String password, {String? name}) async {
    _loading = true; notifyListeners();
    try {
      final (t, u) = await _api.register(email: email, password: password, name: name);
      _token = t; _user = u;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _loading = true; notifyListeners();
    try {
      final (t, u) = await _api.login(email: email, password: password);
      _token = t; _user = u;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null; _user = null;
    await TokenStorage.clear();
    notifyListeners();
  }
}
