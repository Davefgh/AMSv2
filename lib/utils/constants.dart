class AppConstants {
  // API
  static const String apiBaseUrl =
      'https://lanes-parallel-phi-saver.trycloudflare.com';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String storageKeyUser = 'user';
  static const String storageKeyToken = 'token';
  static const String storageKeyTheme = 'theme';

  // Messages
  static const String errorMessage = 'Something went wrong';
  static const String noInternetMessage = 'No internet connection';
  static const String loadingMessage = 'Loading...';

  // Pagination
  static const int pageSize = 20;
}
