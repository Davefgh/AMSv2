import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/theme/app_theme.dart';
import 'config/routes/app_routes.dart';
import 'providers/app_provider.dart';
import 'screens/shared/auth/login_screen.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'utils/constants.dart';

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

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize user role once on widget initialization
    ref.read(appProvider.notifier).setUserRole(widget.initialRole);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'AMSv2',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: widget.initialRoute,
      routes: {
        '/': (context) => const LoginScreen(),
        ...AppRoutes.routes,
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
