import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTypography {
  static const String _monoFamily = 'JetBrainsMono';

  // Sans-serif scale — system font (null family laisse Flutter choisir Roboto sur Android).
  static const TextStyle display = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.contentPrimary,
  );

  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.contentPrimary,
  );

  static const TextStyle heading = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.contentPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.contentPrimary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.contentSecondary,
    letterSpacing: 0.96, // 0.08em à 12px
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.contentMuted,
  );

  static const TextStyle micro = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.contentSecondary,
    letterSpacing: 1.0, // 0.10em à 10px
  );

  // Mono scale — JetBrains Mono.
  static const TextStyle monoBody = TextStyle(
    fontFamily: _monoFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.contentPrimary,
  );

  static const TextStyle monoCode = TextStyle(
    fontFamily: _monoFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.contentPrimary,
  );

  static const TextStyle monoData = TextStyle(
    fontFamily: _monoFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.contentMuted,
  );
}
