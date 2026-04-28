import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/presentation/design/tokens/app_colors.dart';

void main() {
  group('AppColors', () {
    test('palette tokens are non-null Colors', () {
      expect(AppColors.bgCanvas, const Color(0xFF0A0A0A));
      expect(AppColors.bgSurface, const Color(0xFF121212));
      expect(AppColors.bgRaised, const Color(0xFF1A1A1A));
      expect(AppColors.borderSubtle, const Color(0xFF1F1F1F));
      expect(AppColors.borderDefault, const Color(0xFF2A2A2A));
      expect(AppColors.contentPrimary, const Color(0xFFE8FFE8));
      expect(AppColors.contentSecondary, const Color(0xFFA8C8A8));
      expect(AppColors.contentMuted, const Color(0xFF5F8F5F));
      expect(AppColors.contentDisabled, const Color(0xFF3A4A3A));
      expect(AppColors.accentPrimary, const Color(0xFF3FCB3F));
      expect(AppColors.accentPressed, const Color(0xFF2A8A2A));
      expect(AppColors.accentNeon, const Color(0xFF00FF41));
      expect(AppColors.stateSuccess, AppColors.accentPrimary);
      expect(AppColors.stateWarning, const Color(0xFFF2B84B));
      expect(AppColors.stateError, const Color(0xFFFF5C5C));
      expect(AppColors.stateInfo, const Color(0xFF5FB8E8));
    });

    test('focusGlow returns BoxShadow with neon color matching state', () {
      final accent = AppColors.focusGlow(FocusGlowState.accent);
      expect(accent.color, const Color.fromRGBO(0, 255, 65, 0.35));
      expect(accent.blurRadius, 12);
      expect(accent.spreadRadius, 0);

      final error = AppColors.focusGlow(FocusGlowState.error);
      expect(error.color, const Color.fromRGBO(255, 0, 64, 0.60));
      expect(error.blurRadius, 16);

      final warning = AppColors.focusGlow(FocusGlowState.warning);
      expect(warning.color, const Color.fromRGBO(255, 170, 0, 0.50));
      expect(warning.blurRadius, 14);

      final info = AppColors.focusGlow(FocusGlowState.info);
      expect(info.color, const Color.fromRGBO(0, 200, 255, 0.40));
      expect(info.blurRadius, 14);
    });
  });
}
