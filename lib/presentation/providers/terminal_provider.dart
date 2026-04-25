import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xterm/xterm.dart';

part 'terminal_provider.g.dart';

@riverpod
Terminal terminal(Ref ref, String sessionId) {
  final t = Terminal();
  ref.onDispose(() {});
  return t;
}
