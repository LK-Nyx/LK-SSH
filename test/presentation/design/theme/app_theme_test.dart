import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/presentation/design/theme/app_theme.dart';
import 'package:lk_ssh/presentation/design/tokens/app_colors.dart';

void main() {
  group('AppTheme.dark', () {
    final theme = AppTheme.dark();

    test('uses Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('maps colorScheme to design tokens', () {
      expect(theme.colorScheme.primary, AppColors.accentPrimary);
      expect(theme.colorScheme.surface, AppColors.bgSurface);
      expect(theme.colorScheme.onSurface, AppColors.contentPrimary);
      expect(theme.colorScheme.error, AppColors.stateError);
      expect(theme.scaffoldBackgroundColor, AppColors.bgCanvas);
    });

    test('appBar inherits canvas + accent', () {
      expect(theme.appBarTheme.backgroundColor, AppColors.bgCanvas);
      expect(theme.appBarTheme.foregroundColor, AppColors.accentPrimary);
      expect(theme.appBarTheme.elevation, 0);
    });

    test('textTheme exposes design typography', () {
      expect(theme.textTheme.titleLarge?.fontSize, 20);
      expect(theme.textTheme.bodyMedium?.fontSize, 14);
      expect(theme.textTheme.labelMedium?.fontSize, 12);
    });
  });
}
