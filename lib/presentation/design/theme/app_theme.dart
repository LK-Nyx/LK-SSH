import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';

abstract final class AppTheme {
  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.accentPrimary,
      onPrimary: AppColors.bgCanvas,
      surface: AppColors.bgSurface,
      onSurface: AppColors.contentPrimary,
      error: AppColors.stateError,
      onError: AppColors.bgCanvas,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgCanvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgCanvas,
        foregroundColor: AppColors.accentPrimary,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        displaySmall: AppTypography.display,
        titleLarge: AppTypography.title,
        titleMedium: AppTypography.heading,
        bodyMedium: AppTypography.body,
        labelMedium: AppTypography.label,
        bodySmall: AppTypography.caption,
        labelSmall: AppTypography.micro,
      ),
      iconTheme: const IconThemeData(color: AppColors.contentSecondary),
      dividerColor: AppColors.borderSubtle,
    );
  }
}
