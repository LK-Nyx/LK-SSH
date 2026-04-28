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

    testWidgets('isActive=true exposes activeMarker on widget', (tester) async {
      await tester.pumpWidget(_wrap(const AppTile(
        title: 'active',
        isActive: true,
      )));
      final root = tester.widget<AppTile>(find.byType(AppTile));
      expect(root.isActive, isTrue);
    });
  });
}
