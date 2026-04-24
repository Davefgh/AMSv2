import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class AppProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  String _userRole = 'user';
  bool _isLoading = false;

  bool get isDarkMode => _isDarkMode;
  String get userRole => _userRole;
  bool get isLoading => _isLoading;

  AppProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final savedTheme = StorageService.getString(AppConstants.storageKeyTheme);
    _isDarkMode = savedTheme != 'light';
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await StorageService.setString(
      AppConstants.storageKeyTheme,
      _isDarkMode ? 'dark' : 'light',
    );
    notifyListeners();
  }

  void setUserRole(String role) {
    _userRole = role;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
