import 'package:flutter/material.dart';

/// Responsive utility for scaling UI values across different screen sizes.
///
/// Design baseline: 375 x 812 (iPhone 13 standard).
/// Call [Responsive.init] once in the widget tree before using extensions.
class Responsive {
  static late double _screenWidth;
  static late double _screenHeight;

  // Design baseline dimensions (iPhone 13)
  static const double _designWidth = 375.0;
  static const double _designHeight = 812.0;

  /// Initialize with the current [BuildContext]. Call once in your app's
  /// top-level builder or in the root widget's build method.
  static void init(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _screenWidth = mediaQuery.size.width;
    _screenHeight = mediaQuery.size.height;
  }

  /// Scale a value proportionally to screen width.
  static double w(num value) {
    return value * (_screenWidth / _designWidth);
  }

  /// Scale a value proportionally to screen height.
  static double h(num value) {
    return value * (_screenHeight / _designHeight);
  }

  /// Scale a font size proportionally to screen width, with clamping
  /// to prevent text from becoming too small or too large.
  /// Applies a dampened scaling factor so fonts don't change as aggressively.
  static double sp(num value) {
    final scaleFactor = _screenWidth / _designWidth;
    // Dampen the scaling: move only 60% of the way from 1.0 toward the
    // actual scale factor, so fonts stay readable on all sizes.
    final dampened = 1.0 + (scaleFactor - 1.0) * 0.6;
    // Clamp within ±25% of original size
    final clamped = dampened.clamp(0.75, 1.25);
    return value * clamped;
  }

  /// Get the current screen width.
  static double get screenWidth => _screenWidth;

  /// Get the current screen height.
  static double get screenHeight => _screenHeight;
}

/// Extension on [num] for convenient responsive scaling.
///
/// Usage:
/// ```dart
/// fontSize: 16.sp,
/// padding: EdgeInsets.all(20.w),
/// SizedBox(height: 24.h),
/// ```
extension ResponsiveExtension on num {
  /// Width-scaled value.
  double get w => Responsive.w(this);

  /// Height-scaled value.
  double get h => Responsive.h(this);

  /// Font-size scaled value (dampened for readability).
  double get sp => Responsive.sp(this);
}
