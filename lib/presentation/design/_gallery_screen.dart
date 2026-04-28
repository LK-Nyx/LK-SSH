import 'package:flutter/material.dart';
import 'tokens/app_colors.dart';
import 'tokens/app_spacing.dart';
import 'tokens/app_typography.dart';
import 'widgets/app_button.dart';
import 'widgets/app_card.dart';
import 'widgets/app_sheet.dart';
import 'widgets/app_text_field.dart';
import 'widgets/app_tile.dart';

class DesignGalleryScreen extends StatelessWidget {
  const DesignGalleryScreen({super.key});

  Widget _section(String title, Widget child) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.xl2, AppSpacing.lg, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(),
                style: AppTypography.heading.copyWith(
                    color: AppColors.contentSecondary,
                    fontSize: 12,
                    letterSpacing: 1.0)),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design Gallery')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl3),
        children: [
          _section(
            'Buttons',
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppButton(label: 'Primary', onPressed: () {}),
                AppButton(
                    label: 'Secondary',
                    variant: AppButtonVariant.secondary,
                    onPressed: () {}),
                AppButton(
                    label: 'Ghost',
                    variant: AppButtonVariant.ghost,
                    onPressed: () {}),
                AppButton(
                    label: 'Danger',
                    variant: AppButtonVariant.danger,
                    onPressed: () {}),
                const AppButton(label: 'Disabled', onPressed: null),
                AppButton(label: 'Loading', isLoading: true, onPressed: () {}),
              ],
            ),
          ),
          _section(
            'TextFields',
            const Column(
              children: [
                AppTextField(label: 'Host', hint: 'Domaine ou IP'),
                SizedBox(height: AppSpacing.md),
                AppTextField(label: 'User', errorText: 'User requis'),
                SizedBox(height: AppSpacing.md),
                AppTextField(
                    label: 'Fingerprint', mono: true, hint: 'SHA256:…'),
                SizedBox(height: AppSpacing.md),
                AppTextField(label: 'Disabled', enabled: false),
              ],
            ),
          ),
          _section(
            'Tiles',
            Column(
              children: [
                AppTile(
                    title: 'prod-vps',
                    subtitle: 'root@1.2.3.4:22',
                    leading: AppTileLeading.text('SSH'),
                    trailing: AppTileTrailing.chevron(),
                    onTap: () {}),
                AppTile(
                    title: 'staging',
                    subtitle: 'deploy@10.0.0.5:22',
                    leading: AppTileLeading.text('SSH'),
                    trailing: AppTileTrailing.indicator(AppColors.stateSuccess),
                    isActive: true,
                    onTap: () {}),
                AppTile(
                    title: 'backup-nas',
                    subtitle: 'admin@nas.lan:2222',
                    badge: const TileBadge(
                        label: 'HOST CHANGED', tone: BadgeTone.warning),
                    trailing: AppTileTrailing.chevron(),
                    onTap: () {}),
              ],
            ),
          ),
          _section(
            'Card',
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppCard(
                headerTitle: 'Authentication',
                headerTrailing:
                    const Text('key', style: AppTypography.monoData),
                footer: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                        label: 'Change',
                        variant: AppButtonVariant.ghost,
                        onPressed: () {}),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                        label: 'Manage',
                        variant: AppButtonVariant.secondary,
                        onPressed: () {}),
                  ],
                ),
                child: const Text('Card body content'),
              ),
            ),
          ),
          _section(
            'Sheet',
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Builder(builder: (ctx) {
                return AppButton(
                  label: 'Open sheet',
                  onPressed: () => showAppSheet<void>(
                    context: ctx,
                    title: 'Host key changed',
                    subtitle: 'prod.example.com:22 — fingerprint different',
                    actions: [
                      AppButton(
                          label: 'Cancel',
                          variant: AppButtonVariant.ghost,
                          onPressed: () => Navigator.pop(ctx)),
                      AppButton(
                          label: 'Reject',
                          variant: AppButtonVariant.danger,
                          onPressed: () => Navigator.pop(ctx)),
                    ],
                    child: const Text('SHA256:Nc6Fxv…',
                        style: AppTypography.monoCode),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
