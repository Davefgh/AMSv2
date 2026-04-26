import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

part 'app_provider.g.dart';

/// App state model containing theme and user information
class AppState {
  final bool isDarkMode;
  final String userRole;
  final bool isLoading;

  const AppState({
    required this.isDarkMode,
    required this.userRole,
    required this.isLoading,
  });

  AppState copyWith({
    bool? isDarkMode,
    String? userRole,
    bool? isLoading,
  }) {
    return AppState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      userRole: userRole ?? this.userRole,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Main app provider managing theme and user state
@Riverpod(keepAlive: true)
class App extends _$App {
  @override
  AppState build() {
    // Load theme preference synchronously
    final savedTheme = StorageService.getString(AppConstants.storageKeyTheme);
    final isDark = savedTheme != 'light';

    // Return initial state with loaded theme preference
    return AppState(
      isDarkMode: isDark,
      userRole: 'user',
      isLoading: false,
    );
  }

  Future<void> toggleDarkMode() async {
    final newDarkMode = !state.isDarkMode;

    await StorageService.setString(
      AppConstants.storageKeyTheme,
      newDarkMode ? 'dark' : 'light',
    );

    state = state.copyWith(isDarkMode: newDarkMode);
  }

  void setUserRole(String role) {
    state = state.copyWith(userRole: role);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
}
