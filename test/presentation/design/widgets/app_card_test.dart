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
      await tester.pumpWidget(_wrap(const AppCard(
        footer: Row(children: [Text('action')]),
        child: Text('body'),
      )));
      expect(find.text('action'), findsOneWidget);
    });
  });
}
