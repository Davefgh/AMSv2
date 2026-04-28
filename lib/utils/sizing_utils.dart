import 'package:flutter/material.dart';
import 'dart:math' as math;

class Sizing {
  static late MediaQueryData _mediaQueryData;
  static double screenWidth = 375.0;
  static double screenHeight = 812.0;

  static double _safeAreaHorizontal = 0;
  static double _safeAreaVertical = 0;
  static double safeBlockHorizontal = 3.75;
  static double safeBlockVertical = 8.12;

  static double devicePixelRatio = 1.0;
  static double textScaleFactor = 1.0;

  // Base design dimensions (Standard Mobile: 375x812)
  static const double _designWidth = 375.0;
  static const double _designHeight = 812.0;

  static void init(BuildContext context) {
    // Use View.of(context) instead of MediaQuery.of(context) to avoid
    // layout-phase dependencies that can cause "!_debugDoingThisLayout" errors.
    final view = View.of(context);
    devicePixelRatio = view.devicePixelRatio;
    
    // Physical size to logical size
    final logicalSize = view.physicalSize / devicePixelRatio;
    screenWidth = logicalSize.width;
    screenHeight = logicalSize.height;
    
    // We can still get padding from MediaQuery if available, but safely
    final mq = MediaQuery.maybeOf(context);
    if (mq != null) {
      _mediaQueryData = mq;
      textScaleFactor = mq.textScaler.scale(1.0);
      _safeAreaHorizontal = mq.padding.left + mq.padding.right;
      _safeAreaVertical = mq.padding.top + mq.padding.bottom;
    } else {
      textScaleFactor = 1.0;
      _safeAreaHorizontal = 0;
      _safeAreaVertical = 0;
    }

    safeBlockHorizontal = (screenWidth - _safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - _safeAreaVertical) / 100;
  }

  /// Scaled width based on design width
  static double w(double width) {
    return (width / _designWidth) * screenWidth;
  }

  /// Scaled height based on design height
  static double h(double height) {
    return (height / _designHeight) * screenHeight;
  }

  /// Scaled text size (SP)
  static double sp(double fontSize) {
    final scale = math.min(screenWidth / _designWidth, 1.5);
    return fontSize * scale * textScaleFactor;
  }

  /// Scaled Radius
  static double r(double radius) {
    return radius * (screenWidth / _designWidth);
  }

  /// Get percentage of screen width
  static double sw(double percent) => screenWidth * (percent / 100);

  /// Get percentage of screen height
  static double sh(double percent) => screenHeight * (percent / 100);
}
