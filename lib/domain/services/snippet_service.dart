import '../../core/result.dart';

final class SnippetService {
  SnippetService._();

  static final _varRegex = RegExp(r'\{(\w+)\}');

  static List<String> extractVariables(String template) =>
      _varRegex.allMatches(template).map((m) => m.group(1)!).toSet().toList();

  static Result<String, String> resolve(
    String template,
    Map<String, String> variables,
  ) {
    final missing = extractVariables(template)
        .where((v) => !variables.containsKey(v))
        .toList();

    if (missing.isNotEmpty) {
      return Err('Variables manquantes: ${missing.join(', ')}');
    }

    var result = template;
    for (final entry in variables.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return Ok(result);
  }
}
