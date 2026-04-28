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
