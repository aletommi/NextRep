import 'package:flutter/material.dart';
import '../services/database_service.dart';

/// Local-only authentication: the app has no backend, so login just
/// remembers that the user went through the welcome flow.
class AuthProvider extends ChangeNotifier {
  final DatabaseService _db;

  bool _isAuthenticated;

  AuthProvider(this._db)
    : _isAuthenticated = _db.authBox.get(
        'isAuthenticated',
        defaultValue: false,
      );

  bool get isAuthenticated => _isAuthenticated;

  Future<void> login(String email, String password) => _setAuthenticated(true);

  Future<void> register(String email, String password) =>
      _setAuthenticated(true);

  Future<void> logout() => _setAuthenticated(false);

  Future<void> _setAuthenticated(bool value) async {
    _isAuthenticated = value;
    await _db.authBox.put('isAuthenticated', value);
    notifyListeners();
  }
}
