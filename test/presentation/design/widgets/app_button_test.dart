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
      await tester.pumpWidget(_wrap(
        const AppButton(label: 'Connect', onPressed: null),
      ));
      await tester.tap(find.byType(AppButton));
      // No callback to verify; tapping a null-onPressed button must not crash.
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
