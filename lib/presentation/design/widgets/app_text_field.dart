import 'package:flutter/material.dart';
import '../tokens/app_borders.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.obscureText = false,
    this.multiline = false,
    this.mono = false,
    this.prefixIcon,
    this.onChanged,
    this.enabled = true,
  });

  final String label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final bool obscureText;
  final bool multiline;
  final bool mono;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final BorderSide side = hasError
        ? AppBorders.error
        : (_focused ? AppBorders.focus : AppBorders.standard);

    final List<BoxShadow> shadow = !widget.enabled
        ? const []
        : _focused
            ? [
                AppColors.focusGlow(
                  hasError ? FocusGlowState.error : FocusGlowState.accent,
                ),
              ]
            : const [];

    final TextStyle valueStyle =
        widget.mono ? AppTypography.monoBody : AppTypography.body;

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label.toUpperCase(), style: AppTypography.label),
          const SizedBox(height: AppSpacing.xs + 2),
          AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.decelerate,
            decoration: BoxDecoration(
              color: AppColors.bgCanvas,
              borderRadius: AppRadius.all8,
              border: Border.fromBorderSide(side),
              boxShadow: shadow,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                if (widget.prefixIcon != null) ...[
                  Icon(widget.prefixIcon,
                      size: 16, color: AppColors.contentMuted),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    obscureText: widget.obscureText,
                    enabled: widget.enabled,
                    onChanged: widget.onChanged,
                    minLines: widget.multiline ? 3 : 1,
                    maxLines: widget.multiline ? null : 1,
                    style: valueStyle,
                    cursorColor: AppColors.accentPrimary,
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Text(
            widget.errorText ?? widget.hint ?? '',
            style: hasError
                ? AppTypography.caption.copyWith(color: AppColors.stateError)
                : AppTypography.caption,
          ),
        ],
      ),
    );
  }
}
