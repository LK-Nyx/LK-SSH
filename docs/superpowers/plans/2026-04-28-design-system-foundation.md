# Design System Foundation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal :** poser les tokens, le theme et 5 primitives `App*` qui matérialisent le design system "matrix raffiné" défini dans le spec, sans toucher aux écrans existants.

**Architecture :** Dart consts dans `lib/presentation/design/tokens/` consommés par `app_theme.dart` (mapping vers `ThemeData` Material 3) et par 5 widgets dans `lib/presentation/design/widgets/`. JetBrains Mono embarquée comme asset font. Une gallery debug est exposée via Settings → Debug pour valider sur device. Les écrans existants ne sont pas migrés vers les primitives dans ce sous-projet — seul `main.dart` adopte le nouveau theme.

**Tech Stack :** Flutter 3.19+ · Dart 3.3+ · Material 3 · `flutter_test` (déjà au projet) · JetBrains Mono (Regular + Bold) en woff/ttf statique.

**Spec :** [`docs/superpowers/specs/2026-04-28-design-system-foundation-design.md`](../specs/2026-04-28-design-system-foundation-design.md)

---

## Vue d'ensemble du file structure

```
lib/presentation/design/
├── tokens/
│   ├── app_colors.dart
│   ├── app_typography.dart
│   ├── app_spacing.dart
│   ├── app_radius.dart
│   ├── app_borders.dart
│   └── app_motion.dart
├── theme/
│   └── app_theme.dart
└── widgets/
    ├── app_button.dart
    ├── app_text_field.dart
    ├── app_tile.dart
    ├── app_card.dart
    └── app_sheet.dart

assets/fonts/
├── JetBrainsMono-Regular.ttf
└── JetBrainsMono-Bold.ttf

test/presentation/design/
├── tokens/
│   └── app_colors_test.dart            (smoke test)
├── theme/
│   └── app_theme_test.dart
└── widgets/
    ├── app_button_test.dart
    ├── app_text_field_test.dart
    ├── app_tile_test.dart
    ├── app_card_test.dart
    └── app_sheet_test.dart

lib/presentation/design/
└── _gallery_screen.dart                (debug-only, sous design/ pour cohérence)
```

Chaque fichier de tokens a une responsabilité unique. Les widgets consomment les tokens, jamais des magic values.

---

## Task 0: Préparation — créer la branche

- [ ] **Step 1 : Vérifier qu'on est sur main et à jour**

```bash
git checkout main
git pull --ff-only origin main
git status   # doit être propre
```

- [ ] **Step 2 : Créer la branche**

```bash
git checkout -b feat/design-system-foundation
```

Toutes les commits suivants atterrissent sur cette branche. La PR finale (Task 15) la pousse et l'ouvre.

---

## Task 1: Tokens couleurs

**Files :**
- Create : `lib/presentation/design/tokens/app_colors.dart`
- Test : `test/presentation/design/tokens/app_colors_test.dart`

- [ ] **Step 1 : Écrire le test smoke**

```dart
// test/presentation/design/tokens/app_colors_test.dart
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
```

- [ ] **Step 2 : Lancer le test, vérifier qu'il échoue**

Run : `flutter test test/presentation/design/tokens/app_colors_test.dart`
Expected : FAIL — `AppColors` introuvable.

- [ ] **Step 3 : Implémenter `app_colors.dart`**

```dart
// lib/presentation/design/tokens/app_colors.dart
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
```

- [ ] **Step 4 : Lancer le test, vérifier qu'il passe**

Run : `flutter test test/presentation/design/tokens/app_colors_test.dart`
Expected : PASS.

- [ ] **Step 5 : Commit**

```bash
git add lib/presentation/design/tokens/app_colors.dart test/presentation/design/tokens/app_colors_test.dart
git commit -m "feat(design): AppColors tokens (palette + focusGlow)"
```

---

## Task 2: Tokens espacement, radius, motion

Pas besoin de tests dédiés (consts triviaux ; les widgets les exerceront). Trois fichiers, un commit.

**Files :**
- Create : `lib/presentation/design/tokens/app_spacing.dart`
- Create : `lib/presentation/design/tokens/app_radius.dart`
- Create : `lib/presentation/design/tokens/app_motion.dart`

- [ ] **Step 1 : `app_spacing.dart`**

```dart
// lib/presentation/design/tokens/app_spacing.dart
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xl2 = 24;
  static const double xl3 = 32;
  static const double xl4 = 40;
  static const double xl5 = 48;
  static const double xl6 = 64;
}
```

- [ ] **Step 2 : `app_radius.dart`**

```dart
// lib/presentation/design/tokens/app_radius.dart
import 'package:flutter/widgets.dart';

abstract final class AppRadius {
  static const Radius sharp = Radius.zero;
  static const Radius sm = Radius.circular(4);
  static const Radius md = Radius.circular(8);
  static const Radius lg = Radius.circular(12);
  static const Radius sheet = Radius.circular(16);

  static const BorderRadius all0 = BorderRadius.zero;
  static const BorderRadius all4 = BorderRadius.all(sm);
  static const BorderRadius all8 = BorderRadius.all(md);
  static const BorderRadius all12 = BorderRadius.all(lg);
  static const BorderRadius topSheet =
      BorderRadius.vertical(top: sheet);
}
```

- [ ] **Step 3 : `app_motion.dart`**

```dart
// lib/presentation/design/tokens/app_motion.dart
import 'package:flutter/animation.dart';

abstract final class AppMotion {
  // Durations
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
  static const Duration lazy = Duration(milliseconds: 500);

  // Curves
  static const Curve standard = Curves.easeInOut;
  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve decelerate = Curves.easeOut;
  static const Curve accelerate = Curves.easeIn;
}
```

- [ ] **Step 4 : Vérifier la compilation**

Run : `flutter analyze --fatal-infos`
Expected : No issues found.

- [ ] **Step 5 : Commit**

```bash
git add lib/presentation/design/tokens/app_spacing.dart lib/presentation/design/tokens/app_radius.dart lib/presentation/design/tokens/app_motion.dart
git commit -m "feat(design): AppSpacing, AppRadius, AppMotion tokens"
```

---

## Task 3: Tokens bordures

**Files :**
- Create : `lib/presentation/design/tokens/app_borders.dart`

- [ ] **Step 1 : Implémenter `app_borders.dart`**

```dart
// lib/presentation/design/tokens/app_borders.dart
import 'package:flutter/widgets.dart';
import 'app_colors.dart';

abstract final class AppBorders {
  /// 1dp · borderSubtle — dividers, hairlines.
  static const BorderSide hair = BorderSide(
    color: AppColors.borderSubtle,
    width: 1,
  );

  /// 1dp · borderDefault — cards, inputs au repos.
  static const BorderSide standard = BorderSide(
    color: AppColors.borderDefault,
    width: 1,
  );

  /// 1dp · accentPrimary — input/card focusé. Width inchangée.
  static const BorderSide focus = BorderSide(
    color: AppColors.accentPrimary,
    width: 1,
  );

  /// 1dp · stateError — input en erreur.
  static const BorderSide error = BorderSide(
    color: AppColors.stateError,
    width: 1,
  );

  /// 3dp left only — marker `AppTile.isActive`.
  static const BorderSide activeMarker = BorderSide(
    color: AppColors.accentPrimary,
    width: 3,
  );
}
```

- [ ] **Step 2 : Vérifier la compilation**

Run : `flutter analyze --fatal-infos`
Expected : No issues found.

- [ ] **Step 3 : Commit**

```bash
git add lib/presentation/design/tokens/app_borders.dart
git commit -m "feat(design): AppBorders presets"
```

---

## Task 4: Embarquer JetBrains Mono

**Files :**
- Create : `assets/fonts/JetBrainsMono-Regular.ttf` (download)
- Create : `assets/fonts/JetBrainsMono-Bold.ttf` (download)
- Modify : `pubspec.yaml`

- [ ] **Step 1 : Télécharger les fichiers TTF**

```bash
mkdir -p assets/fonts
curl -L -o assets/fonts/JetBrainsMono-Regular.ttf \
  https://github.com/JetBrains/JetBrainsMono/raw/master/fonts/ttf/JetBrainsMono-Regular.ttf
curl -L -o assets/fonts/JetBrainsMono-Bold.ttf \
  https://github.com/JetBrains/JetBrainsMono/raw/master/fonts/ttf/JetBrainsMono-Bold.ttf
ls -lh assets/fonts/
```

Expected : deux fichiers `.ttf` ≈ 200KB chacun.

- [ ] **Step 2 : Déclarer dans `pubspec.yaml`**

Localiser la section `flutter:` dans `pubspec.yaml`. Ajouter sous l'arborescence :

```yaml
flutter:
  uses-material-design: true
  fonts:
    - family: JetBrainsMono
      fonts:
        - asset: assets/fonts/JetBrainsMono-Regular.ttf
        - asset: assets/fonts/JetBrainsMono-Bold.ttf
          weight: 700
```

Si une section `assets:` ou `fonts:` existe déjà, fusionner sans dupliquer.

- [ ] **Step 3 : Récupérer les assets**

Run : `flutter pub get`
Expected : succès.

- [ ] **Step 4 : Vérifier que la font est résolue**

Run : `flutter analyze --fatal-infos` (pas d'erreur sur `pubspec.yaml`).

Run rapide d'un widget mono pour valider sur device si possible :
```bash
flutter run -d <device>
# Vérifier que dans le terminal, le texte mono utilise déjà la nouvelle font une fois Task 5 terminée.
```

- [ ] **Step 5 : Commit**

```bash
git add assets/fonts/JetBrainsMono-Regular.ttf assets/fonts/JetBrainsMono-Bold.ttf pubspec.yaml pubspec.lock
git commit -m "feat(design): bundle JetBrains Mono font (regular + bold)"
```

---

## Task 5: Tokens typographie

**Files :**
- Create : `lib/presentation/design/tokens/app_typography.dart`

- [ ] **Step 1 : Implémenter `app_typography.dart`**

```dart
// lib/presentation/design/tokens/app_typography.dart
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
```

- [ ] **Step 2 : Vérifier la compilation**

Run : `flutter analyze --fatal-infos`
Expected : No issues found.

- [ ] **Step 3 : Commit**

```bash
git add lib/presentation/design/tokens/app_typography.dart
git commit -m "feat(design): AppTypography tokens (sans + JetBrains Mono)"
```

---

## Task 6: AppTheme (mapping ThemeData)

**Files :**
- Create : `lib/presentation/design/theme/app_theme.dart`
- Test : `test/presentation/design/theme/app_theme_test.dart`

- [ ] **Step 1 : Écrire le test**

```dart
// test/presentation/design/theme/app_theme_test.dart
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
      // Material 3 names → tokens
      expect(theme.textTheme.titleLarge?.fontSize, 20);
      expect(theme.textTheme.bodyMedium?.fontSize, 14);
      expect(theme.textTheme.labelMedium?.fontSize, 12);
    });
  });
}
```

- [ ] **Step 2 : Lancer le test, vérifier qu'il échoue**

Run : `flutter test test/presentation/design/theme/app_theme_test.dart`
Expected : FAIL — `AppTheme` introuvable.

- [ ] **Step 3 : Implémenter `app_theme.dart`**

```dart
// lib/presentation/design/theme/app_theme.dart
import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';

abstract final class AppTheme {
  static ThemeData dark() {
    final colorScheme = const ColorScheme.dark(
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
```

- [ ] **Step 4 : Lancer le test, vérifier qu'il passe**

Run : `flutter test test/presentation/design/theme/app_theme_test.dart`
Expected : PASS.

- [ ] **Step 5 : Commit**

```bash
git add lib/presentation/design/theme/app_theme.dart test/presentation/design/theme/app_theme_test.dart
git commit -m "feat(design): AppTheme.dark() mapping vers ThemeData M3"
```

---

## Task 7: AppButton

**Files :**
- Create : `lib/presentation/design/widgets/app_button.dart`
- Test : `test/presentation/design/widgets/app_button_test.dart`

- [ ] **Step 1 : Écrire le test**

```dart
// test/presentation/design/widgets/app_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/presentation/design/widgets/app_button.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AppButton', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(label: 'Connect', onPressed: () {}),
      ));
      expect(find.text('Connect'), findsOneWidget);
    });

    testWidgets('fires onPressed on tap', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(_wrap(
        AppButton(label: 'Connect', onPressed: () => pressed++),
      ));
      await tester.tap(find.byType(AppButton));
      expect(pressed, 1);
    });

    testWidgets('does not fire onPressed when disabled', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(_wrap(
        AppButton(label: 'Connect', onPressed: () => pressed++)
            .copyWithDisabled(),
      ));
      await tester.tap(find.byType(AppButton));
      expect(pressed, 0);
    });

    testWidgets('isLoading replaces label with spinner', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(label: 'Connect', onPressed: () {}, isLoading: true),
      ));
      expect(find.text('Connect'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('isLoading ignores onPressed', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(_wrap(
        AppButton(
          label: 'Connect',
          onPressed: () => pressed++,
          isLoading: true,
        ),
      ));
      await tester.tap(find.byType(AppButton));
      expect(pressed, 0);
    });

    testWidgets('renders all 4 variants', (tester) async {
      for (final variant in AppButtonVariant.values) {
        await tester.pumpWidget(_wrap(
          AppButton(label: variant.name, variant: variant, onPressed: () {}),
        ));
        expect(find.text(variant.name), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  });
}

extension on AppButton {
  AppButton copyWithDisabled() => AppButton(
        label: label,
        variant: variant,
        onPressed: null,
        isLoading: isLoading,
        leadingIcon: leadingIcon,
      );
}
```

- [ ] **Step 2 : Lancer le test, vérifier qu'il échoue**

Run : `flutter test test/presentation/design/widgets/app_button_test.dart`
Expected : FAIL — `AppButton` introuvable.

- [ ] **Step 3 : Implémenter `app_button.dart`**

```dart
// lib/presentation/design/widgets/app_button.dart
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
        transform: Matrix4.identity()..scale(_pressed ? 0.97 : 1.0),
        transformAlignment: Alignment.center,
        child: Center(child: child),
      ),
    );
  }
}
```

- [ ] **Step 4 : Lancer le test, vérifier qu'il passe**

Run : `flutter test test/presentation/design/widgets/app_button_test.dart`
Expected : PASS.

- [ ] **Step 5 : Commit**

```bash
git add lib/presentation/design/widgets/app_button.dart test/presentation/design/widgets/app_button_test.dart
git commit -m "feat(design): AppButton (4 variantes, 5 états, loading)"
```

---

## Task 8: AppTextField

**Files :**
- Create : `lib/presentation/design/widgets/app_text_field.dart`
- Test : `test/presentation/design/widgets/app_text_field_test.dart`

- [ ] **Step 1 : Écrire le test**

```dart
// test/presentation/design/widgets/app_text_field_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/presentation/design/widgets/app_text_field.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AppTextField', () {
    testWidgets('renders label and hint when no error', (tester) async {
      await tester.pumpWidget(_wrap(const AppTextField(
        label: 'Host',
        hint: 'Domaine ou IP',
      )));
      expect(find.text('HOST'), findsOneWidget);
      expect(find.text('Domaine ou IP'), findsOneWidget);
    });

    testWidgets('renders errorText instead of hint when present',
        (tester) async {
      await tester.pumpWidget(_wrap(const AppTextField(
        label: 'User',
        hint: 'Optionnel',
        errorText: 'User requis',
      )));
      expect(find.text('User requis'), findsOneWidget);
      expect(find.text('Optionnel'), findsNothing);
    });

    testWidgets('writes through controller', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(_wrap(
        AppTextField(label: 'Host', controller: controller),
      ));
      await tester.enterText(find.byType(TextField), 'example.com');
      expect(controller.text, 'example.com');
    });

    testWidgets('mono toggle uses JetBrainsMono family', (tester) async {
      await tester.pumpWidget(_wrap(const AppTextField(
        label: 'Host',
        mono: true,
      )));
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.style?.fontFamily, 'JetBrainsMono');
    });
  });
}
```

- [ ] **Step 2 : Lancer le test, vérifier qu'il échoue**

Run : `flutter test test/presentation/design/widgets/app_text_field_test.dart`
Expected : FAIL.

- [ ] **Step 3 : Implémenter `app_text_field.dart`**

```dart
// lib/presentation/design/widgets/app_text_field.dart
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
              vertical: AppSpacing.sm + 2,
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
```

- [ ] **Step 4 : Lancer le test, vérifier qu'il passe**

Run : `flutter test test/presentation/design/widgets/app_text_field_test.dart`
Expected : PASS.

- [ ] **Step 5 : Commit**

```bash
git add lib/presentation/design/widgets/app_text_field.dart test/presentation/design/widgets/app_text_field_test.dart
git commit -m "feat(design): AppTextField (focus glow couleur-conditionné)"
```

---

## Task 9: AppTile

**Files :**
- Create : `lib/presentation/design/widgets/app_tile.dart`
- Test : `test/presentation/design/widgets/app_tile_test.dart`

- [ ] **Step 1 : Écrire le test**

```dart
// test/presentation/design/widgets/app_tile_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/presentation/design/widgets/app_tile.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AppTile', () {
    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(_wrap(const AppTile(
        title: 'staging',
        subtitle: 'deploy@10.0.0.5:22',
      )));
      expect(find.text('staging'), findsOneWidget);
      expect(find.text('deploy@10.0.0.5:22'), findsOneWidget);
    });

    testWidgets('fires onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(AppTile(
        title: 't',
        onTap: () => taps++,
      )));
      await tester.tap(find.byType(AppTile));
      expect(taps, 1);
    });

    testWidgets('renders badge when provided', (tester) async {
      await tester.pumpWidget(_wrap(const AppTile(
        title: 'backup-nas',
        badge: TileBadge(label: 'HOST CHANGED', tone: BadgeTone.warning),
      )));
      expect(find.text('HOST CHANGED'), findsOneWidget);
    });

    testWidgets('isActive=true exposes activeMarker color', (tester) async {
      await tester.pumpWidget(_wrap(const AppTile(
        title: 'active',
        isActive: true,
      )));
      // Le widget root doit exposer `isActive` via un key reconnaissable
      final root = tester.widget<AppTile>(find.byType(AppTile));
      expect(root.isActive, isTrue);
    });
  });
}
```

- [ ] **Step 2 : Lancer le test, vérifier qu'il échoue**

Run : `flutter test test/presentation/design/widgets/app_tile_test.dart`
Expected : FAIL.

- [ ] **Step 3 : Implémenter `app_tile.dart`**

```dart
// lib/presentation/design/widgets/app_tile.dart
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

class AppTileTrailing {
  const AppTileTrailing._({this.kind = _Kind.none, this.color});
  final _Kind kind;
  final Color? color;

  factory AppTileTrailing.chevron() =>
      const AppTileTrailing._(kind: _Kind.chevron);
  factory AppTileTrailing.indicator(Color color) =>
      AppTileTrailing._(kind: _Kind.indicator, color: color);
  factory AppTileTrailing.none() => const AppTileTrailing._();
}

enum _Kind { none, chevron, indicator }

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
    if (t == null || t.kind == _Kind.none) return null;
    if (t.kind == _Kind.chevron) {
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
```

- [ ] **Step 4 : Lancer le test, vérifier qu'il passe**

Run : `flutter test test/presentation/design/widgets/app_tile_test.dart`
Expected : PASS.

- [ ] **Step 5 : Commit**

```bash
git add lib/presentation/design/widgets/app_tile.dart test/presentation/design/widgets/app_tile_test.dart
git commit -m "feat(design): AppTile (leading/trailing/badge/isActive)"
```

---

## Task 10: AppCard

**Files :**
- Create : `lib/presentation/design/widgets/app_card.dart`
- Test : `test/presentation/design/widgets/app_card_test.dart`

- [ ] **Step 1 : Écrire le test**

```dart
// test/presentation/design/widgets/app_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/presentation/design/widgets/app_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AppCard', () {
    testWidgets('renders body alone when no header/footer', (tester) async {
      await tester.pumpWidget(_wrap(const AppCard(
        child: Text('body content'),
      )));
      expect(find.text('body content'), findsOneWidget);
    });

    testWidgets('renders header title uppercase', (tester) async {
      await tester.pumpWidget(_wrap(const AppCard(
        headerTitle: 'Authentication',
        child: Text('body'),
      )));
      expect(find.text('AUTHENTICATION'), findsOneWidget);
    });

    testWidgets('renders headerTrailing slot', (tester) async {
      await tester.pumpWidget(_wrap(const AppCard(
        headerTitle: 'Auth',
        headerTrailing: Text('key'),
        child: Text('body'),
      )));
      expect(find.text('key'), findsOneWidget);
    });

    testWidgets('renders footer slot', (tester) async {
      await tester.pumpWidget(_wrap(AppCard(
        child: const Text('body'),
        footer: Row(children: const [Text('action')]),
      )));
      expect(find.text('action'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2 : Lancer le test, vérifier qu'il échoue**

Run : `flutter test test/presentation/design/widgets/app_card_test.dart`
Expected : FAIL.

- [ ] **Step 3 : Implémenter `app_card.dart`**

```dart
// lib/presentation/design/widgets/app_card.dart
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
        vertical: AppSpacing.md - 2,
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
      decoration: BoxDecoration(
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
```

- [ ] **Step 4 : Lancer le test, vérifier qu'il passe**

Run : `flutter test test/presentation/design/widgets/app_card_test.dart`
Expected : PASS.

- [ ] **Step 5 : Commit**

```bash
git add lib/presentation/design/widgets/app_card.dart test/presentation/design/widgets/app_card_test.dart
git commit -m "feat(design): AppCard (header/body/footer slots)"
```

---

## Task 11: AppSheet + showAppSheet helper

**Files :**
- Create : `lib/presentation/design/widgets/app_sheet.dart`
- Test : `test/presentation/design/widgets/app_sheet_test.dart`

- [ ] **Step 1 : Écrire le test**

```dart
// test/presentation/design/widgets/app_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/presentation/design/widgets/app_sheet.dart';

void main() {
  group('AppSheet', () {
    testWidgets('renders title, subtitle, body, actions', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppSheet(
            title: 'Host key changed',
            subtitle: 'fingerprint different',
            child: const Text('diff content'),
            actions: const [
              Text('Cancel'),
              Text('Reject'),
            ],
          ),
        ),
      ));
      expect(find.text('Host key changed'), findsOneWidget);
      expect(find.text('fingerprint different'), findsOneWidget);
      expect(find.text('diff content'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });

    testWidgets('omits subtitle when null', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppSheet(
            title: 'Confirm',
            child: const Text('body'),
            actions: const [Text('OK')],
          ),
        ),
      ));
      // subtitle absent → seul le title est rendu en plus du body et actions
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('showAppSheet displays the sheet via Navigator',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (ctx) {
            return ElevatedButton(
              onPressed: () => showAppSheet<void>(
                context: ctx,
                title: 'Test',
                child: const Text('body content'),
                actions: const [Text('Close')],
              ),
              child: const Text('open'),
            );
          }),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('body content'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2 : Lancer le test, vérifier qu'il échoue**

Run : `flutter test test/presentation/design/widgets/app_sheet_test.dart`
Expected : FAIL.

- [ ] **Step 3 : Implémenter `app_sheet.dart`**

```dart
// lib/presentation/design/widgets/app_sheet.dart
import 'package:flutter/material.dart';
import '../tokens/app_borders.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.title,
    required this.child,
    required this.actions,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        side: AppBorders.hair,
        borderRadius: AppRadius.topSheet,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.title),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle!,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.contentMuted)),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: child,
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: AppBorders.hair),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (final a in actions) ...[
                    a,
                    if (a != actions.last)
                      const SizedBox(width: AppSpacing.sm),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<T?> showAppSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  required List<Widget> actions,
  String? subtitle,
  bool isScrollControlled = true,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    backgroundColor: Colors.transparent,
    builder: (ctx) => AppSheet(
      title: title,
      subtitle: subtitle,
      actions: actions,
      child: child,
    ),
  );
}
```

- [ ] **Step 4 : Lancer le test, vérifier qu'il passe**

Run : `flutter test test/presentation/design/widgets/app_sheet_test.dart`
Expected : PASS.

- [ ] **Step 5 : Commit**

```bash
git add lib/presentation/design/widgets/app_sheet.dart test/presentation/design/widgets/app_sheet_test.dart
git commit -m "feat(design): AppSheet + showAppSheet helper"
```

---

## Task 12: Gallery debug screen

**Files :**
- Create : `lib/presentation/design/_gallery_screen.dart`

Pas de test (écran debug uniquement, validation visuelle sur device).

- [ ] **Step 1 : Implémenter la gallery**

```dart
// lib/presentation/design/_gallery_screen.dart
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
          _section('Buttons', Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
            AppButton(label: 'Primary', onPressed: () {}),
            AppButton(label: 'Secondary', variant: AppButtonVariant.secondary, onPressed: () {}),
            AppButton(label: 'Ghost', variant: AppButtonVariant.ghost, onPressed: () {}),
            AppButton(label: 'Danger', variant: AppButtonVariant.danger, onPressed: () {}),
            const AppButton(label: 'Disabled', onPressed: null),
            AppButton(label: 'Loading', isLoading: true, onPressed: () {}),
          ])),
          _section('TextFields', Column(children: [
            const AppTextField(label: 'Host', hint: 'Domaine ou IP'),
            const SizedBox(height: AppSpacing.md),
            const AppTextField(label: 'User', errorText: 'User requis'),
            const SizedBox(height: AppSpacing.md),
            const AppTextField(label: 'Fingerprint', mono: true, hint: 'SHA256:…'),
            const SizedBox(height: AppSpacing.md),
            const AppTextField(label: 'Disabled', enabled: false),
          ])),
          _section('Tiles', Column(children: [
            AppTile(title: 'prod-vps', subtitle: 'root@1.2.3.4:22',
                leading: AppTileLeading.text('SSH'),
                trailing: AppTileTrailing.chevron(),
                onTap: () {}),
            AppTile(title: 'staging', subtitle: 'deploy@10.0.0.5:22',
                leading: AppTileLeading.text('SSH'),
                trailing: AppTileTrailing.indicator(AppColors.stateSuccess),
                isActive: true, onTap: () {}),
            AppTile(title: 'backup-nas', subtitle: 'admin@nas.lan:2222',
                badge: const TileBadge(label: 'HOST CHANGED', tone: BadgeTone.warning),
                trailing: AppTileTrailing.chevron(),
                onTap: () {}),
          ])),
          _section('Card', Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppCard(
              headerTitle: 'Authentication',
              headerTrailing: Text('key', style: AppTypography.monoData),
              child: const Text('Card body content'),
              footer: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                AppButton(label: 'Change', variant: AppButtonVariant.ghost, onPressed: () {}),
                const SizedBox(width: AppSpacing.sm),
                AppButton(label: 'Manage', variant: AppButtonVariant.secondary, onPressed: () {}),
              ]),
            ),
          )),
          _section('Sheet', Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppButton(
              label: 'Open sheet',
              onPressed: () => showAppSheet<void>(
                context: context,
                title: 'Host key changed',
                subtitle: 'prod.example.com:22 — fingerprint different',
                child: Text('SHA256:Nc6Fxv…',
                    style: AppTypography.monoCode),
                actions: [
                  AppButton(label: 'Cancel', variant: AppButtonVariant.ghost,
                      onPressed: () => Navigator.pop(context)),
                  AppButton(label: 'Reject', variant: AppButtonVariant.danger,
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2 : Vérifier la compilation**

Run : `flutter analyze --fatal-infos`
Expected : No issues found.

- [ ] **Step 3 : Commit**

```bash
git add lib/presentation/design/_gallery_screen.dart
git commit -m "feat(design): debug Design Gallery screen"
```

---

## Task 13: Wire la gallery dans Settings (debug-only)

**Files :**
- Modify : `lib/presentation/screens/settings_screen.dart`

- [ ] **Step 1 : Lire le fichier pour repérer la section Debug**

Run : `grep -n "debug\|Debug\|DebugLog\|kDebugMode" lib/presentation/screens/settings_screen.dart`

Identifier la section "Debug" existante (où `DebugLogService` est déjà accessible) et la place où ajouter une row.

- [ ] **Step 2 : Ajouter l'import et la row**

En haut de `settings_screen.dart`, ajouter :

```dart
import 'package:flutter/foundation.dart' show kDebugMode;
import '../design/_gallery_screen.dart';
```

Dans la section debug du body (à la suite des entrées debug existantes, avant la fermeture de la section), ajouter :

```dart
if (kDebugMode)
  ListTile(
    title: const Text('Design Gallery'),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const DesignGalleryScreen(),
      ),
    ),
  ),
```

Si `settings_screen.dart` n'a pas encore de section debug visible, ajouter la row directement dans la liste principale derrière le `kDebugMode` guard.

- [ ] **Step 3 : Vérifier**

Run : `flutter analyze --fatal-infos`
Expected : No issues found.

- [ ] **Step 4 : Commit**

```bash
git add lib/presentation/screens/settings_screen.dart
git commit -m "feat(design): expose Design Gallery in Settings (debug only)"
```

---

## Task 14: Adopter `AppTheme.dark()` dans `main.dart`

**Files :**
- Modify : `lib/main.dart`

- [ ] **Step 1 : Lire la fonction `_appTheme()` actuelle**

Run : `sed -n '155,170p' lib/main.dart`

Confirmer la signature inline `ThemeData _appTheme() => ThemeData.dark(useMaterial3: true).copyWith(...)`.

- [ ] **Step 2 : Remplacer par AppTheme**

Au début du fichier, ajouter :

```dart
import 'presentation/design/theme/app_theme.dart';
```

Remplacer la fonction `_appTheme()` par `AppTheme.dark()` aux deux call sites (`MaterialApp(theme: _appTheme())` → `MaterialApp(theme: AppTheme.dark())`).

Supprimer la fonction `_appTheme()` une fois inutilisée.

- [ ] **Step 3 : Vérifier la compilation et l'analyzer**

Run : `flutter analyze --fatal-infos`
Expected : No issues found.

- [ ] **Step 4 : Lancer la suite de tests**

Run : `flutter test`
Expected : tous les tests passent (les tests existants ne dépendent pas du theme spécifique).

- [ ] **Step 5 : Smoke test sur device (manuel)**

Run : `flutter run -d <device>`

Vérifier sur device :
1. L'app boot et la Server List s'affiche correctement (couleurs cohérentes avec le nouveau theme).
2. Settings → Debug → Design Gallery est accessible (uniquement en build debug).
3. Tous les widgets de la gallery s'affichent correctement.
4. La font JetBrains Mono est rendue sur les inputs `mono: true` et les terminal-style data.
5. Le focus glow vert apparaît sur les inputs focusés.
6. Le focus glow rouge punchy apparaît sur les inputs en `error + focus` simultanés.

- [ ] **Step 6 : Commit**

```bash
git add lib/main.dart
git commit -m "feat(design): adopter AppTheme.dark() dans main.dart"
```

---

## Task 15: Vérification finale & documentation

**Files :**
- Modify : `docs/TECHNICAL.md` (ajouter section "Design system")

- [ ] **Step 1 : Lancer la suite complète**

Run :
```bash
flutter analyze --fatal-infos
flutter test
```

Expected : tout vert.

- [ ] **Step 2 : Compter les tests ajoutés**

Run : `flutter test --reporter compact 2>&1 | tail -5`

Expected : voir le compteur augmenter d'au moins 20 tests (tokens + theme + 5 primitives).

- [ ] **Step 3 : Documenter dans TECHNICAL.md**

Ajouter à la fin de `docs/TECHNICAL.md` une section :

```markdown
---

## Design System Foundation

Sous-projet implémenté sur la branche `feat/design-system-foundation`.
Spec : [`docs/superpowers/specs/2026-04-28-design-system-foundation-design.md`](superpowers/specs/2026-04-28-design-system-foundation-design.md).
Plan : [`docs/superpowers/plans/2026-04-28-design-system-foundation.md`](superpowers/plans/2026-04-28-design-system-foundation.md).

### Tokens

`lib/presentation/design/tokens/` — `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppBorders`, `AppMotion`. Direction "matrix raffiné" (noir #0A0A0A + accent vert sage #3FCB3F + neon #00FF41 réservé au focus glow). Police mono = JetBrains Mono (embarquée), sans = system Roboto.

### Focus glow

Règle : `border` reste la teinte calme et lisible (corail #FF5C5C en erreur, sage #3FCB3F en accent), `glow` utilise la version neon de la même teinte. `AppColors.focusGlow(state)` retourne le `BoxShadow` paramétré.

### Primitives

`lib/presentation/design/widgets/` — `AppButton`, `AppTextField`, `AppTile`, `AppCard`, `AppSheet` + helper `showAppSheet`. Les écrans existants ne sont pas migrés vers ces primitives dans ce sous-projet.

### Gallery debug

`Settings → Debug → Design Gallery` (visible uniquement en `kDebugMode`) liste toutes les primitives et leurs états pour validation visuelle sur device.
```

- [ ] **Step 4 : Commit**

```bash
git add docs/TECHNICAL.md
git commit -m "docs: section design system foundation dans TECHNICAL.md"
```

- [ ] **Step 5 : Push et PR**

```bash
git push -u origin feat/design-system-foundation
gh pr create --title "feat: design system foundation (matrix refined)" --body "$(cat <<'EOF'
## Summary
- Tokens : `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppBorders`, `AppMotion`
- Theme : `AppTheme.dark()` mapping vers ThemeData M3
- 5 primitives : `AppButton`, `AppTextField`, `AppTile`, `AppCard`, `AppSheet`
- JetBrains Mono embarquée
- Design Gallery accessible via Settings → Debug

## Hors scope
- Refactor des écrans existants vers les primitives (sous-projets ultérieurs).

## Test plan
- [ ] `flutter analyze --fatal-infos` vert
- [ ] `flutter test` vert
- [ ] App boot OK, Server List rendue correctement
- [ ] Design Gallery accessible et tous les widgets s'affichent
- [ ] Focus glow vert sur inputs focusés
- [ ] Focus glow rouge punchy sur input `error + focus`
- [ ] JetBrains Mono rendue sur les inputs `mono: true`

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Critères de complétion (rappel spec)

- [x] Tokens compilent et sont consommables (Tasks 1-5).
- [x] 5 primitives existent avec API documentée et tests (Tasks 7-11).
- [x] `app_theme.dart` produit un `ThemeData` sans warning (Task 6 + 14).
- [x] JetBrains Mono s'affiche sur device (Task 4 + 14 step 5).
- [x] `flutter analyze --fatal-infos` vert (Task 15).
- [x] `flutter test` vert (Task 15).
- [x] Gallery debug accessible (Tasks 12-13).
