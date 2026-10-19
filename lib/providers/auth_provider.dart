import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class AuthProvider extends ChangeNotifier {
  static const String authBoxName = 'auth';

  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Determine if we need to open the box or if it's opened in main/db service
    if (!Hive.isBoxOpen(authBoxName)) {
      await Hive.openBox(authBoxName);
    }
    final box = Hive.box(authBoxName);
    _isAuthenticated = box.get('isAuthenticated', defaultValue: false);
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    // Mock validation
    await Future.delayed(const Duration(seconds: 1)); // Simulate visual delay

    _isAuthenticated = true;
    final box = Hive.box(authBoxName);
    await box.put('isAuthenticated', true);
    notifyListeners();
  }

  Future<void> register(String email, String password) async {
    // Mock registration
    await Future.delayed(const Duration(seconds: 1));

    _isAuthenticated = true; // Auto login after register
    final box = Hive.box(authBoxName);
    await box.put('isAuthenticated', true);
    notifyListeners();
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    final box = Hive.box(authBoxName);
    await box.put('isAuthenticated', false);
    notifyListeners();
  }
}
