import 'package:flutter/material.dart';
import 'dart:math' as math;

class Sizing {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double _blockSizeHorizontal;
  static late double _blockSizeVertical;

  static late double _safeAreaHorizontal;
  static late double _safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;

  static late double devicePixelRatio;
  static late double textScaleFactor;

  // Base design dimensions (Standard Mobile: 375x812)
  static const double _designWidth = 375.0;
  static const double _designHeight = 812.0;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    devicePixelRatio = _mediaQueryData.devicePixelRatio;
    textScaleFactor = _mediaQueryData.textScaler.scale(1.0); // Simple scale factor

    _blockSizeHorizontal = screenWidth / 100;
    _blockSizeVertical = screenHeight / 100;

    _safeAreaHorizontal = _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    _safeAreaVertical = _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
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
  /// Uses a combination of width scaling and text scale factor for readability
  static double sp(double fontSize) {
    // We use a base scale from width but cap it to prevent massive text on tablets
    // unless they specifically want it.
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
