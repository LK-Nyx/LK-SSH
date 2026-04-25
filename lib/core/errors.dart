sealed class AppError {
  const AppError();

  String get message;
}

final class SshConnectionError extends AppError {
  const SshConnectionError(this.message);
  @override
  final String message;
}

final class SshAuthError extends AppError {
  const SshAuthError(this.message);
  @override
  final String message;
}

final class StorageError extends AppError {
  const StorageError(this.message);
  @override
  final String message;
}

final class KeyNotFoundError extends AppError {
  const KeyNotFoundError();
  @override
  String get message => 'Aucune clé SSH configurée. Ajoutez-en une dans les paramètres.';
}

final class KeyDecryptionError extends AppError {
  const KeyDecryptionError();
  @override
  String get message => 'Passphrase incorrecte ou clé corrompue.';
}
