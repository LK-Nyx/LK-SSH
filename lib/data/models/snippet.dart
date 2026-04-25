import 'package:freezed_annotation/freezed_annotation.dart';

part 'snippet.freezed.dart';
part 'snippet.g.dart';

@freezed
class Snippet with _$Snippet {
  const factory Snippet({
    required String id,
    required String label,
    required String command,
    required String categoryId,
    @Default(false) bool requireConfirm,
  }) = _Snippet;

  factory Snippet.fromJson(Map<String, dynamic> json) =>
      _$SnippetFromJson(json);
}
