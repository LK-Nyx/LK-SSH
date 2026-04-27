abstract interface class IKnownHostsStorage {
  Future<String?> load(String host, int port);
  Future<void> save(String host, int port, String fingerprint);
  Future<void> delete(String host, int port);
}
