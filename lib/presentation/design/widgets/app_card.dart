import 'package:flutter/material.dart';
import '../tokens/app_borders.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.headerTitle,
    this.headerTrailing,
    this.footer,
  });

  final Widget child;
  final String? headerTitle;
  final Widget? headerTrailing;
  final Widget? footer;

  Widget? _header() {
    if (headerTitle == null && headerTrailing == null) return null;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: AppBorders.hair),
      ),
      child: Row(
        children: [
          if (headerTitle != null)
            Expanded(
              child: Text(
                headerTitle!.toUpperCase(),
                style: AppTypography.heading.copyWith(
                  color: AppColors.contentSecondary,
                  fontSize: 12,
                  letterSpacing: 0.96,
                ),
              ),
            )
          else
            const Spacer(),
          if (headerTrailing != null) headerTrailing!,
        ],
      ),
    );
  }

  Widget? _footer() {
    if (footer == null) return null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgCanvas,
        border: Border(top: AppBorders.hair),
      ),
      child: footer!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = _header();
    final f = _footer();
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.fromBorderSide(AppBorders.standard),
        borderRadius: AppRadius.all12,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (h != null) h,
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
          if (f != null) f,
        ],
      ),
    );
  }
}
