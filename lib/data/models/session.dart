import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';
part 'session.g.dart';

enum SessionStatus { connecting, connected, disconnected, error }

@freezed
class Session with _$Session {
  const factory Session({
    required String id,
    required String serverId,
    required String label,
    @Default(SessionStatus.connecting) SessionStatus status,
  }) = _Session;

  factory Session.fromJson(Map<String, dynamic> json) =>
      _$SessionFromJson(json);
}
