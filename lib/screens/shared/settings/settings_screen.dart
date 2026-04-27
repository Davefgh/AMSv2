import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/routes/app_routes.dart';
import '../../../providers/app_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Preferences',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme'),
            value: appState.isDarkMode,
            onChanged: (_) {
              ref.read(appProvider.notifier).toggleDarkMode();
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Attendance and check-in alerts'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.notifications);
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Privacy'),
            subtitle: const Text('Manage privacy settings'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy settings')),
              );
            },
          ),
          const SizedBox(height: 30),
          const Text(
            'About',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const ListTile(
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            title: const Text('About AMSv2'),
            subtitle: const Text('Learn more about this app'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              showAboutDialog(context: context);
            },
          ),
        ],
      ),
    );
  }
}
