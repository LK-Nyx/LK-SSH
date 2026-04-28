import 'package:flutter/material.dart';

enum FocusGlowState { accent, error, warning, info }

abstract final class AppColors {
  // Surfaces
  static const Color bgCanvas = Color(0xFF0A0A0A);
  static const Color bgSurface = Color(0xFF121212);
  static const Color bgRaised = Color(0xFF1A1A1A);
  static const Color borderSubtle = Color(0xFF1F1F1F);
  static const Color borderDefault = Color(0xFF2A2A2A);

  // Content
  static const Color contentPrimary = Color(0xFFE8FFE8);
  static const Color contentSecondary = Color(0xFFA8C8A8);
  static const Color contentMuted = Color(0xFF5F8F5F);
  static const Color contentDisabled = Color(0xFF3A4A3A);

  // Accent
  static const Color accentPrimary = Color(0xFF3FCB3F);
  static const Color accentPressed = Color(0xFF2A8A2A);
  static const Color accentNeon = Color(0xFF00FF41);

  // Semantic states
  static const Color stateSuccess = accentPrimary;
  static const Color stateWarning = Color(0xFFF2B84B);
  static const Color stateError = Color(0xFFFF5C5C);
  static const Color stateInfo = Color(0xFF5FB8E8);

  // Focus glow — base neon de la teinte, opacités/blur calibrés par état.
  static BoxShadow focusGlow(FocusGlowState state) {
    switch (state) {
      case FocusGlowState.accent:
        return const BoxShadow(
          color: Color.fromRGBO(0, 255, 65, 0.35),
          blurRadius: 12,
        );
      case FocusGlowState.error:
        return const BoxShadow(
          color: Color.fromRGBO(255, 0, 64, 0.60),
          blurRadius: 16,
        );
      case FocusGlowState.warning:
        return const BoxShadow(
          color: Color.fromRGBO(255, 170, 0, 0.50),
          blurRadius: 14,
        );
      case FocusGlowState.info:
        return const BoxShadow(
          color: Color.fromRGBO(0, 200, 255, 0.40),
          blurRadius: 14,
        );
    }
  }
}
