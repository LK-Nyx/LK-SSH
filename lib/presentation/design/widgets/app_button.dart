import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.leadingIcon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? leadingIcon;
  final bool isLoading;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  Color _bgColor() {
    if (!_enabled && !widget.isLoading) return AppColors.bgRaised;
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return _pressed ? AppColors.accentPressed : AppColors.accentPrimary;
      case AppButtonVariant.secondary:
        return _pressed
            ? AppColors.accentPrimary.withValues(alpha: 0.16)
            : Colors.transparent;
      case AppButtonVariant.ghost:
        return _pressed ? AppColors.bgRaised : Colors.transparent;
      case AppButtonVariant.danger:
        return _pressed
            ? AppColors.stateError.withValues(alpha: 0.12)
            : Colors.transparent;
    }
  }

  Color _fgColor() {
    if (!_enabled && !widget.isLoading) return AppColors.contentDisabled;
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.bgCanvas;
      case AppButtonVariant.secondary:
        return AppColors.accentPrimary;
      case AppButtonVariant.ghost:
        return _pressed ? AppColors.contentPrimary : AppColors.contentSecondary;
      case AppButtonVariant.danger:
        return AppColors.stateError;
    }
  }

  Border? _border() {
    switch (widget.variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.ghost:
        return null;
      case AppButtonVariant.secondary:
        return Border.all(color: AppColors.accentPrimary, width: 1);
      case AppButtonVariant.danger:
        return Border.all(color: AppColors.stateError, width: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = _fgColor();
    final child = widget.isLoading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.leadingIcon != null) ...[
                Icon(widget.leadingIcon, size: 18, color: fg),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                widget.label,
                style: AppTypography.body.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    return GestureDetector(
      onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
      onTap: _enabled ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: AppMotion.instant,
        curve: AppMotion.standard,
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: _bgColor(),
          border: _border(),
          borderRadius: AppRadius.all8,
        ),
        transform: Matrix4.identity()..scaleByDouble(_pressed ? 0.97 : 1.0,
            _pressed ? 0.97 : 1.0, 1.0, 1.0),
        transformAlignment: Alignment.center,
        child: Center(child: child),
      ),
    );
  }
}
