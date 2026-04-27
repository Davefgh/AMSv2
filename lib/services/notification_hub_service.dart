import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

typedef NotificationCallback = void Function(NotificationModel notification);
typedef AccessTokenRefreshCallback = Future<bool> Function();

class NotificationHubService {
  static final NotificationHubService _instance =
      NotificationHubService._internal();
  factory NotificationHubService() => _instance;
  NotificationHubService._internal();

  final Logger _logger = Logger();
  HubConnection? _hubConnection;
  NotificationCallback? _onNotification;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;
  bool get isConnecting => _isConnecting;

  void setOnNotification(NotificationCallback callback) {
    _onNotification = callback;
  }

  @visibleForTesting
  void triggerTestNotification(NotificationModel notification) {
    _onNotification?.call(notification);
  }

  static String deriveHubUrl(String apiBaseUrl) {
    var url = apiBaseUrl.trim();
    // Remove trailing slash
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    // Remove /api suffix if present
    if (url.endsWith('/api')) {
      url = url.substring(0, url.length - 4);
    }
    // Append /notificationHub
    return '$url/notificationHub';
  }

  static Future<String> Function() createAccessTokenFactory({
    AccessTokenRefreshCallback? refreshToken,
  }) {
    return () async {
      var token = StorageService.getString(AppConstants.storageKeyToken) ?? '';
      if (token.isEmpty && refreshToken != null) {
        final refreshed = await refreshToken();
        if (refreshed) {
          token = StorageService.getString(AppConstants.storageKeyToken) ?? '';
        }
      }
      return token;
    };
  }

  Future<void> start() async {
    if (_isConnecting || isConnected) return;

    final tokenFactory = createAccessTokenFactory(
      refreshToken: ApiService().tryRefreshToken,
    );
    var token = await tokenFactory();
    if (token.isEmpty) {
      _logger.w('Cannot start notification hub: no access token');
      return;
    }

    _isConnecting = true;

    try {
      final hubUrl = deriveHubUrl(AppConstants.apiBaseUrl);
      _logger.i('Starting SignalR connection to $hubUrl');

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: tokenFactory,
            ),
          )
          .build();

      _hubConnection!.on('ReceiveNotification', (args) {
        _logger.i('ReceiveNotification invoked with args: $args');
        if (args != null && args.isNotEmpty && args[0] != null) {
          try {
            final payload = args[0] as Map<String, dynamic>;
            final notification = NotificationModel.fromJson(payload);
            if (_isValidNotification(notification)) {
              _onNotification?.call(notification);
            } else {
              _logger.w('Invalid notification payload received, skipping');
            }
          } catch (e) {
            _logger.e('Failed to parse notification payload: $e');
          }
        }
      });

      _hubConnection!.onclose(({Exception? error}) {
        _logger.w('SignalR connection closed: $error');
        _isConnecting = false;
        if (error != null) {
          _attemptReconnect();
        }
      });

      await _hubConnection!.start();
      _reconnectAttempts = 0;
      _logger.i('SignalR connection started successfully');
    } catch (e) {
      _logger.e('Failed to start SignalR connection: $e');
      _attemptReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> stop() async {
    _reconnectAttempts =
        _maxReconnectAttempts; // Prevent auto-reconnect after explicit stop
    if (_hubConnection != null) {
      try {
        await _hubConnection!.stop();
        _logger.i('SignalR connection stopped');
      } catch (e) {
        _logger.e('Error stopping SignalR connection: $e');
      } finally {
        _hubConnection = null;
        _isConnecting = false;
      }
    }
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.w('Max reconnect attempts reached, giving up');
      return;
    }

    _reconnectAttempts++;
    final delaySeconds = min(pow(2, _reconnectAttempts).toInt(), 30);
    _logger.i(
        'Attempting reconnect in ${delaySeconds}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)');

    Future.delayed(Duration(seconds: delaySeconds), () {
      start();
    });
  }

  bool _isValidNotification(NotificationModel notification) {
    return notification.title.isNotEmpty && notification.message.isNotEmpty;
  }
}
