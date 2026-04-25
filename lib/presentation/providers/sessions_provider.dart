import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/session.dart';

part 'sessions_provider.g.dart';

@riverpod
class SessionsNotifier extends _$SessionsNotifier {
  @override
  List<Session> build() => [];

  String open(String serverId, String serverLabel) {
    final existing = state.where((s) => s.serverId == serverId).length;
    final id = const Uuid().v4();
    final label = existing == 0 ? serverLabel : '$serverLabel:${existing + 1}';
    state = [...state, Session(id: id, serverId: serverId, label: label)];
    return id;
  }

  void updateStatus(String id, SessionStatus status) {
    state = state
        .map((s) => s.id == id ? s.copyWith(status: status) : s)
        .toList();
  }

  void close(String id) {
    state = state.where((s) => s.id != id).toList();
  }
}
