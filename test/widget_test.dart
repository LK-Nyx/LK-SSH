import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lk_ssh/main.dart';

void main() {
  testWidgets('LkSshApp smoke test — démarre sans crash', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LkSshApp()));
  });
}
