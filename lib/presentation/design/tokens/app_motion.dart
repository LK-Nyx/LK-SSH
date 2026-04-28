import 'package:flutter/animation.dart';

abstract final class AppMotion {
  // Durations
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
  static const Duration lazy = Duration(milliseconds: 500);

  // Curves
  static const Curve standard = Curves.easeInOut;
  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve decelerate = Curves.easeOut;
  static const Curve accelerate = Curves.easeIn;
}
