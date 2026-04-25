sealed class AppError {
  const AppError();
}

final class SshConnectionError extends AppError {
  const SshConnectionError(this.message);
  final String message;
}

final class SshAuthError extends AppError {
  const SshAuthError(this.message);
  final String message;
}

final class StorageError extends AppError {
  const StorageError(this.message);
  final String message;
}

final class KeyNotFoundError extends AppError {
  const KeyNotFoundError();
}

final class KeyDecryptionError extends AppError {
  const KeyDecryptionError();
}
