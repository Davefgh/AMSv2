import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  String toFormattedString() {
    return DateFormat('MMM dd, yyyy').format(this);
  }

  String toTimeString() {
    return DateFormat('hh:mm a').format(this);
  }
}

extension StringExtension on String {
  bool isValidEmail() {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(this);
  }

  bool isValidPhone() {
    final phoneRegex = RegExp(r'^\d{10,}$');
    return phoneRegex.hasMatch(this.replaceAll(RegExp(r'\D'), ''));
  }
}
