import 'package:flutter/material.dart';
import 'database.dart';
import 'models.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoading = false;
  String? _errorMessage;

  final DatabaseHelper _db = DatabaseHelper.instance;

  // Getters
  User? get currentUser => _currentUser;
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isCashier => _currentUser?.isCashier ?? false;

  // Login
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _db.login(username, password);
      
      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Identifiants incorrects';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Toggle theme
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}