abstract interface class IPasswordStorage {
  Future<String?> load(String serverId);
  Future<void> save(String serverId, String password);
  Future<void> delete(String serverId);
}
