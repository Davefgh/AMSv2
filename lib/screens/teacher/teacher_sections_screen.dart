import 'package:flutter/material.dart';
import '../../widgets/main_scaffold.dart';

class TeacherSectionsScreen extends StatelessWidget {
  const TeacherSectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Sections',
      currentIndex: 3,
      isAdmin: false,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_alt_rounded,
              size: 64,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            const Text(
              'Assigned Sections',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your class sections will appear here.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
