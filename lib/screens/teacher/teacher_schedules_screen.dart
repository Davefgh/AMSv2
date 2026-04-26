import 'package:flutter/material.dart';
import '../../widgets/main_scaffold.dart';

class TeacherSchedulesScreen extends StatefulWidget {
  const TeacherSchedulesScreen({super.key});

  @override
  State<TeacherSchedulesScreen> createState() => _TeacherSchedulesScreenState();
}

class _TeacherSchedulesScreenState extends State<TeacherSchedulesScreen> {
  @override
  Widget build(BuildContext context) {
    return const MainScaffold(
      title: 'My Schedules',
      currentIndex: 3,
      isAdmin: false,
      body: Center(
        child: Text(
          'Schedules feature is being refactored...',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
