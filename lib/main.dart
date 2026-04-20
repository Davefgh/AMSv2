import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme/app_theme.dart';
import 'config/routes/app_routes.dart';
import 'providers/app_provider.dart';
import 'screens/shared/auth/login_screen.dart';
import 'services/storage_service.dart';

import 'utils/constants.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();

  final token = StorageService.getString(AppConstants.storageKeyToken);
  final role =
      StorageService.getString(AppConstants.storageKeyRole)?.toLowerCase() ??
          'user';

  String initialRoute = '/';
  if (token != null && token.isNotEmpty) {
    if (role == 'instructor' || role == 'teacher') {
      initialRoute = AppRoutes.teacherDashboard;
    } else if (role == 'student') {
      initialRoute = AppRoutes.studentDashboard;
    } else if (role == 'admin' || role == 'administrator') {
      initialRoute = AppRoutes.dashboard;
    }
  }

  runApp(MyApp(initialRoute: initialRoute, initialRole: role));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final String initialRole;

  const MyApp({super.key, required this.initialRoute, required this.initialRole});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final provider = AppProvider();
          provider.setUserRole(initialRole);
          return provider;
        }),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'AMSv2',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: initialRoute,
        routes: {
          '/': (context) => const LoginScreen(),
          ...AppRoutes.routes,
        },
        debugShowCheckedModeBanner: false,
      ),
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
