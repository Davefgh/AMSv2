import 'package:flutter/material.dart';
import 'sizing_utils.dart';

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  static bool isMobile(BuildContext context) {
    // Try to use Sizing.screenWidth if initialized, otherwise fallback to MediaQuery
    // This is safer during layout phases.
    try {
      return Sizing.screenWidth < 640;
    } catch (_) {
      return MediaQuery.sizeOf(context).width < 640;
    }
  }

  static bool isTablet(BuildContext context) {
    try {
      return Sizing.screenWidth >= 640 && Sizing.screenWidth < 1024;
    } catch (_) {
      final width = MediaQuery.sizeOf(context).width;
      return width >= 640 && width < 1024;
    }
  }

  static bool isDesktop(BuildContext context) {
    try {
      return Sizing.screenWidth >= 1024;
    } catch (_) {
      return MediaQuery.sizeOf(context).width >= 1024;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return desktop;
        } else if (constraints.maxWidth >= 640) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
