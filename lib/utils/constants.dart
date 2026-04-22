class AppConstants {
  // API
  static const String apiBaseUrl =
  'https://oiadyyapw59d.shares.zrok.io';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String storageKeyUser = 'user';
  static const String storageKeyToken = 'accessToken';
  static const String storageKeyRefreshToken = 'refreshToken';
  static const String storageKeyRole = 'userRole';
  static const String storageKeyTheme = 'theme';

  // Messages
  static const String errorMessage = 'Something went wrong';
  static const String noInternetMessage = 'No internet connection';
  static const String loadingMessage = 'Loading...';

  // Pagination
  static const int pageSize = 20;
}
