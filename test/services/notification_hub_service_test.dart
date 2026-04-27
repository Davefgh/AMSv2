import 'package:flutter_test/flutter_test.dart';
import 'package:amsv2/services/notification_hub_service.dart';
import 'package:amsv2/services/storage_service.dart';
import 'package:amsv2/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('NotificationHubService.deriveHubUrl', () {
    test('strips /api suffix and appends /notificationHub', () {
      expect(
        NotificationHubService.deriveHubUrl('http://localhost:8080/api'),
        'http://localhost:8080/notificationHub',
      );
    });

    test('handles trailing slash', () {
      expect(
        NotificationHubService.deriveHubUrl('http://localhost:8080/api/'),
        'http://localhost:8080/notificationHub',
      );
    });

    test('handles URL without /api suffix', () {
      expect(
        NotificationHubService.deriveHubUrl('http://localhost:8080'),
        'http://localhost:8080/notificationHub',
      );
    });

    test('handles emulator LAN URL', () {
      expect(
        NotificationHubService.deriveHubUrl('http://192.168.1.5:8080/api'),
        'http://192.168.1.5:8080/notificationHub',
      );
    });

    test('handles HTTPS deployed URL', () {
      expect(
        NotificationHubService.deriveHubUrl('https://api.example.com/api'),
        'https://api.example.com/notificationHub',
      );
    });
  });

  group('NotificationHubService.createAccessTokenFactory', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();
    });

    test('returns the latest token from storage each time it is invoked',
        () async {
      await StorageService.setString(AppConstants.storageKeyToken, 'old-token');

      final tokenFactory = NotificationHubService.createAccessTokenFactory();

      expect(await tokenFactory(), 'old-token');

      await StorageService.setString(AppConstants.storageKeyToken, 'new-token');

      expect(await tokenFactory(), 'new-token');
    });

    test('refreshes token when no access token is stored', () async {
      var refreshAttempts = 0;

      final tokenFactory = NotificationHubService.createAccessTokenFactory(
        refreshToken: () async {
          refreshAttempts++;
          await StorageService.setString(
            AppConstants.storageKeyToken,
            'refreshed-token',
          );
          return true;
        },
      );

      expect(await tokenFactory(), 'refreshed-token');
      expect(refreshAttempts, 1);
    });

    test('returns empty token when refresh fails', () async {
      final tokenFactory = NotificationHubService.createAccessTokenFactory(
        refreshToken: () async => false,
      );

      expect(await tokenFactory(), isEmpty);
    });
  });
}
