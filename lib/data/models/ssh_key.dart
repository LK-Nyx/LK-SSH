import 'package:freezed_annotation/freezed_annotation.dart';

part 'ssh_key.freezed.dart';
part 'ssh_key.g.dart';

@freezed
class SshKey with _$SshKey {
  const factory SshKey({
    required String id,
    required String label,
    required DateTime addedAt,
  }) = _SshKey;

  factory SshKey.fromJson(Map<String, dynamic> json) => _$SshKeyFromJson(json);
}
