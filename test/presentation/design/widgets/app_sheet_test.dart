import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lk_ssh/presentation/design/widgets/app_sheet.dart';

void main() {
  group('AppSheet', () {
    testWidgets('renders title, subtitle, body, actions', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AppSheet(
            title: 'Host key changed',
            subtitle: 'fingerprint different',
            actions: [
              Text('Cancel'),
              Text('Reject'),
            ],
            child: Text('diff content'),
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
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AppSheet(
            title: 'Confirm',
            actions: [Text('OK')],
            child: Text('body'),
          ),
        ),
      ));
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
