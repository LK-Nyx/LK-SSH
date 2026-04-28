import 'package:flutter/material.dart';
import '../tokens/app_borders.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

enum BadgeTone { success, warning, error, info }

class TileBadge {
  const TileBadge({required this.label, required this.tone});
  final String label;
  final BadgeTone tone;
}

class AppTileLeading {
  const AppTileLeading._({this.text, this.icon});
  final String? text;
  final IconData? icon;
  factory AppTileLeading.text(String text) => AppTileLeading._(text: text);
  factory AppTileLeading.icon(IconData icon) => AppTileLeading._(icon: icon);
}

enum _TrailingKind { none, chevron, indicator }

class AppTileTrailing {
  const AppTileTrailing._({_TrailingKind kind = _TrailingKind.none, this.color})
      : _kind = kind;
  final _TrailingKind _kind;
  final Color? color;

  factory AppTileTrailing.chevron() =>
      const AppTileTrailing._(kind: _TrailingKind.chevron);
  factory AppTileTrailing.indicator(Color color) =>
      AppTileTrailing._(kind: _TrailingKind.indicator, color: color);
  factory AppTileTrailing.none() => const AppTileTrailing._();
}

class AppTile extends StatelessWidget {
  const AppTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.badge,
    this.isActive = false,
    this.onTap,
    this.onLongPress,
  });

  final String title;
  final String? subtitle;
  final AppTileLeading? leading;
  final AppTileTrailing? trailing;
  final TileBadge? badge;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  Color _badgeColor(BadgeTone tone) {
    switch (tone) {
      case BadgeTone.success:
        return AppColors.stateSuccess;
      case BadgeTone.warning:
        return AppColors.stateWarning;
      case BadgeTone.error:
        return AppColors.stateError;
      case BadgeTone.info:
        return AppColors.stateInfo;
    }
  }

  Widget _leadingWidget(AppTileLeading l) {
    final Widget content = l.text != null
        ? Text(l.text!,
            style: AppTypography.monoCode
                .copyWith(color: AppColors.accentPrimary, fontSize: 11))
        : Icon(l.icon, size: 16, color: AppColors.accentPrimary);
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.bgRaised,
        border: Border.all(color: AppColors.borderDefault, width: 1),
        borderRadius: AppRadius.all4,
      ),
      child: content,
    );
  }

  Widget? _trailingWidget(AppTileTrailing? t) {
    if (t == null || t._kind == _TrailingKind.none) return null;
    if (t._kind == _TrailingKind.chevron) {
      return const Icon(Icons.chevron_right,
          size: 18, color: AppColors.contentSecondary);
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: t.color ?? AppColors.accentPrimary,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = _trailingWidget(trailing);
    final bg = isActive ? AppColors.bgRaised : AppColors.bgSurface;
    final border = Border(
      bottom: AppBorders.hair,
      left: isActive ? AppBorders.activeMarker : BorderSide.none,
    );

    Widget titleWidget = Text(title, style: AppTypography.body);
    if (badge != null) {
      titleWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: titleWidget),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm - 2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: _badgeColor(badge!.tone), width: 1),
              borderRadius: AppRadius.all4,
            ),
            child: Text(badge!.label,
                style: AppTypography.micro
                    .copyWith(color: _badgeColor(badge!.tone))),
          ),
        ],
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.standard,
        decoration: BoxDecoration(color: bg, border: border),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              _leadingWidget(leading!),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleWidget,
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTypography.monoData),
                  ],
                ],
              ),
            ),
            if (tr != null) ...[
              const SizedBox(width: AppSpacing.md),
              tr,
            ],
          ],
        ),
      ),
    );
  }
}
