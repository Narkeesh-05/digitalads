import 'package:flutter/material.dart'; class ResponsiveUtil {
  final BuildContext context;
  late final double screenWidth;
  late final double screenHeight;
  late final double _widthScale;
  late final double _heightScale;

  // Design reference size — change if your Figma/design frame differs.
  static const double _baseWidth = 390;
  static const double _baseHeight = 844;

  ResponsiveUtil(this.context) {
    final size = MediaQuery.of(context).size;
    screenWidth = size.width;
    screenHeight = size.height;
    _widthScale = screenWidth / _baseWidth;
    _heightScale = screenHeight / _baseHeight;
  }
  double h(double value) => value * _heightScale;

  /// Scales a width value (e.g. container width, horizontal padding)
  double w(double value) => value * _widthScale;

  /// Scales font size — uses the smaller of the two scale factors so text
  /// doesn't blow up on very wide (tablet) screens.
  double sp(double value) {
    final scale = _widthScale < _heightScale ? _widthScale : _heightScale;
    // Clamp so text never becomes unreadably small or comically large.
    final clamped = scale.clamp(0.85, 1.25);
    return value * clamped;
  }
  double wPercent(double percent) => screenWidth * (percent / 100);

  /// Height as a percentage of screen height (0–100).
  double hPercent(double percent) => screenHeight * (percent / 100);
   bool get isTablet => screenWidth > 700;
  bool get isDesktop => screenWidth > 1100;

  /// Safe area-aware bottom padding (useful for buttons pinned above
  /// gesture nav bars on notched devices).
  double get bottomSafeArea => MediaQuery.of(context).padding.bottom;

  double get topSafeArea => MediaQuery.of(context).padding.top;
}

/// Shorthand extension so you can write `24.h(context)` instead of
/// `ResponsiveUtil(context).h(24)` if you prefer that style.
extension ResponsiveNum on num {
  double h(BuildContext context) => ResponsiveUtil(context).h(toDouble());
  double w(BuildContext context) => ResponsiveUtil(context).w(toDouble());
  double sp(BuildContext context) => ResponsiveUtil(context).sp(toDouble());
}