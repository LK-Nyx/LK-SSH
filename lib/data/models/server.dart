import 'package:freezed_annotation/freezed_annotation.dart';

part 'server.freezed.dart';
part 'server.g.dart';

@freezed
class Server with _$Server {
  const factory Server({
    required String id,
    required String label,
    required String host,
    @Default(22) int port,
    required String username,
  }) = _Server;

  factory Server.fromJson(Map<String, dynamic> json) => _$ServerFromJson(json);
}
