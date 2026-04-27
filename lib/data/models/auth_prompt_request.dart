import 'dart:async';

// SSHUserInfoRequest is not re-exported by the top-level dartssh2.dart.
// ignore: implementation_imports
import 'package:dartssh2/src/ssh_userauth.dart';

sealed class AuthPromptRequest {
  const AuthPromptRequest();
}

final class PasswordPromptRequest extends AuthPromptRequest {
  PasswordPromptRequest({required this.user, required this.host});
  final String user;
  final String host;
  final Completer<String?> completer = Completer<String?>();
}

final class KbInteractivePromptRequest extends AuthPromptRequest {
  KbInteractivePromptRequest(this.request);
  final SSHUserInfoRequest request;
  final Completer<List<String>?> completer = Completer<List<String>?>();
}

final class HostKeyMismatchRequest extends AuthPromptRequest {
  HostKeyMismatchRequest(this.change);
  final HostKeyChange change;
  final Completer<HostKeyDecision> completer = Completer<HostKeyDecision>();
}

enum HostKeyDecision { reject, acceptOnce, acceptAndPin }

class HostKeyChange {
  const HostKeyChange({
    required this.host,
    required this.port,
    required this.oldFingerprint,
    required this.newFingerprint,
  });
  final String host;
  final int port;
  final String oldFingerprint;
  final String newFingerprint;
}
