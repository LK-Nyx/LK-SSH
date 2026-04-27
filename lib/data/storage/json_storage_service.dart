import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' hide Category;

import '../../core/errors.dart';
import '../../core/result.dart';
import '../models/category.dart';
import '../models/server.dart';
import '../models/settings.dart';
import '../models/snippet.dart';
import 'i_storage_service.dart';

final class JsonStorageService implements IStorageService {
  JsonStorageService(this._directory);

  final Directory _directory;

  File _file(String name) => File('${_directory.path}/$name.json');

  Future<Result<List<T>, StorageError>> _loadList<T>(
    String name,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final file = _file(name);
    try {
      if (!await file.exists()) return const Ok([]);
      final decoded = jsonDecode(await file.readAsString()) as List;
      return Ok(decoded.map((e) => fromJson(e as Map<String, dynamic>)).toList());
    } catch (e) {
      // Fichier corrompu : on supprime et on repart vide plutôt que de bloquer l'app.
      try { await file.delete(); } catch (_) {}
      debugPrint('[LK-SSH] $name.json corrompu — reset: $e');
      return const Ok([]);
    }
  }

  Future<Result<void, StorageError>> _saveList<T>(
    String name,
    List<T> items,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    try {
      await _file(name).writeAsString(jsonEncode(items.map(toJson).toList()));
      return const Ok(null);
    } catch (e) {
      return Err(StorageError(e.toString()));
    }
  }

  @override
  Future<Result<List<Server>, StorageError>> loadServers() =>
      _loadList('servers', Server.fromJson);

  @override
  Future<Result<void, StorageError>> saveServers(List<Server> servers) =>
      _saveList('servers', servers, (s) => s.toJson());

  @override
  Future<Result<List<Snippet>, StorageError>> loadSnippets() =>
      _loadList('snippets', Snippet.fromJson);

  @override
  Future<Result<void, StorageError>> saveSnippets(List<Snippet> snippets) =>
      _saveList('snippets', snippets, (s) => s.toJson());

  @override
  Future<Result<List<Category>, StorageError>> loadCategories() =>
      _loadList('categories', Category.fromJson);

  @override
  Future<Result<void, StorageError>> saveCategories(List<Category> categories) =>
      _saveList('categories', categories, (c) => c.toJson());

  @override
  Future<Result<Settings, StorageError>> loadSettings() async {
    final file = _file('settings');
    try {
      if (!await file.exists()) return const Ok(Settings());
      final decoded = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return Ok(Settings.fromJson(decoded));
    } catch (e) {
      try { await file.delete(); } catch (_) {}
      debugPrint('[LK-SSH] settings.json corrompu — reset: $e');
      return const Ok(Settings());
    }
  }

  @override
  Future<Result<void, StorageError>> saveSettings(Settings settings) async {
    try {
      await _file('settings').writeAsString(jsonEncode(settings.toJson()));
      return const Ok(null);
    } catch (e) {
      return Err(StorageError(e.toString()));
    }
  }
}
