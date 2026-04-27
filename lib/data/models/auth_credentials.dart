import 'dart:typed_data';

// SSHUserInfoRequest is not re-exported by the top-level dartssh2.dart.
// ignore: implementation_imports
import 'package:dartssh2/src/ssh_userauth.dart';

sealed class AuthCredentials {
  const AuthCredentials();
}

final class KeyCreds extends AuthCredentials {
  KeyCreds({required this.bytes, this.passphrase});
  final Uint8List bytes;
  final String? passphrase;
}

final class PasswordCreds extends AuthCredentials {
  const PasswordCreds(this.password);
  final String password;
}

final class InteractiveCreds extends AuthCredentials {
  InteractiveCreds(this.onPrompt);
  final Future<List<String>?> Function(SSHUserInfoRequest) onPrompt;
}
