import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/theme/app_theme.dart';
import 'config/routes/app_routes.dart';
import 'providers/app_provider.dart';
import 'models/notification_model.dart';
import 'providers/notification_provider.dart';
import 'screens/shared/auth/login_screen.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'services/notification_hub_service.dart';
import 'utils/constants.dart';
import 'widgets/navigation_shell.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  await StorageService.init();

  final token = StorageService.getString(AppConstants.storageKeyToken);
  final role =
      StorageService.getString(AppConstants.storageKeyRole)?.toLowerCase() ??
          'user';

  String initialRoute = '/';

  if (token != null && token.isNotEmpty) {
    final api = ApiService();

    // Check if token is still valid
    bool isValid = await api.checkToken();

    if (!isValid) {
      // Try to silently refresh
      isValid = await api.tryRefreshToken();
    }

    if (isValid) {
      // Block admin from staying logged in
      if (role == 'instructor' || role == 'teacher') {
        initialRoute = AppRoutes.teacherDashboard;
      } else if (role == 'student') {
        initialRoute = AppRoutes.studentDashboard;
      }
      // admin falls through to login
    } else {
      // Clear stale tokens
      await StorageService.remove(AppConstants.storageKeyToken);
      await StorageService.remove(AppConstants.storageKeyRefreshToken);
      await StorageService.remove(AppConstants.storageKeyUser);
      await StorageService.remove(AppConstants.storageKeyRole);
    }
  }

  runApp(
    ProviderScope(
      child: MyApp(initialRoute: initialRoute, initialRole: role),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  final String initialRoute;
  final String initialRole;

  const MyApp(
      {super.key, required this.initialRoute, required this.initialRole});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize user role and notification hub after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appProvider.notifier).setUserRole(widget.initialRole);
      _setupNotificationHub();
      _startNotificationHub();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _startNotificationHub();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        NotificationHubService().stop();
        break;
      case AppLifecycleState.inactive:
        // Transient state (calls, notifications, biometric prompts) - do not disconnect
        break;
    }
  }

  void _setupNotificationHub() {
    final hub = NotificationHubService();
    hub.setOnNotification((notification) {
      ref.read(notificationProvider.notifier).addNotification(notification);
      _showForegroundSnackBar(notification);
    });
  }

  void _startNotificationHub() {
    final token = StorageService.getString(AppConstants.storageKeyToken);
    final hub = NotificationHubService();
    if (token != null &&
        token.isNotEmpty &&
        !hub.isConnected &&
        !hub.isConnecting) {
      hub.start();
    }
  }

  void _showForegroundSnackBar(NotificationModel notification) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${notification.title}: ${notification.message}'),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(appProvider).isDarkMode;
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'AMSv2',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      initialRoute: widget.initialRoute,
      routes: {
        '/': (context) => const LoginScreen(),
        // Use NavigationShell for main dashboards
        AppRoutes.teacherDashboard: (context) =>
            const NavigationShell(isStudent: false),
        AppRoutes.studentDashboard: (context) =>
            const NavigationShell(isStudent: true),
        // Keep standalone routes that are not part of bottom navigation
        AppRoutes.editProfile: (context) =>
            AppRoutes.routes[AppRoutes.editProfile]!(context),
        AppRoutes.settings: (context) =>
            AppRoutes.routes[AppRoutes.settings]!(context),
        AppRoutes.notifications: (context) =>
            AppRoutes.routes[AppRoutes.notifications]!(context),
        AppRoutes.teacherProfileEdit: (context) =>
            AppRoutes.routes[AppRoutes.teacherProfileEdit]!(context),
        AppRoutes.teacherNotifications: (context) =>
            AppRoutes.routes[AppRoutes.teacherNotifications]!(context),
        AppRoutes.teacherSchedules: (context) =>
            AppRoutes.routes[AppRoutes.teacherSchedules]!(context),
        AppRoutes.studentFingerprint: (context) =>
            AppRoutes.routes[AppRoutes.studentFingerprint]!(context),
        AppRoutes.teacherReports: (context) =>
            AppRoutes.routes[AppRoutes.teacherReports]!(context),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AMSv2'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to AMSv2',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/dashboard');
              },
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
