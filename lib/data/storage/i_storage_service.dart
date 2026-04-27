import '../../core/errors.dart';
import '../../core/result.dart';
import '../models/category.dart';
import '../models/server.dart';
import '../models/settings.dart';
import '../models/snippet.dart';
import '../models/ssh_key.dart';

abstract interface class IStorageService {
  Future<Result<List<Server>, StorageError>> loadServers();
  Future<Result<void, StorageError>> saveServers(List<Server> servers);
  Future<Result<List<Snippet>, StorageError>> loadSnippets();
  Future<Result<void, StorageError>> saveSnippets(List<Snippet> snippets);
  Future<Result<List<Category>, StorageError>> loadCategories();
  Future<Result<void, StorageError>> saveCategories(List<Category> categories);
  Future<Result<Settings, StorageError>> loadSettings();
  Future<Result<void, StorageError>> saveSettings(Settings settings);
  Future<Result<List<SshKey>, StorageError>> loadSshKeys();
  Future<Result<void, StorageError>> saveSshKeys(List<SshKey> keys);
}
