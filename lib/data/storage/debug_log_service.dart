import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DebugLogService {
  DebugLogService._();
  static final instance = DebugLogService._();

  bool _enabled = false;
  File? _file;

  bool get enabled => _enabled;

  String get filePath =>
      _file?.path ??
      '/storage/emulated/0/Android/data/dev.lararchfr.lk_ssh/files/lk-ssh-debug.log';

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    if (value) {
      await _initFile();
    }
  }

  Future<void> _initFile() async {
    try {
      Directory? dir;
      try {
        dir = await getExternalStorageDirectory();
      } catch (_) {
        dir = await getApplicationDocumentsDirectory();
      }
      _file = File('${dir!.path}/lk-ssh-debug.log');
      await _file!.writeAsString(
        '=== LK-SSH Debug Log ===\n'
        'Démarré : ${DateTime.now().toIso8601String()}\n'
        'Chemin   : ${_file!.path}\n'
        '${'-' * 60}\n',
      );
    } catch (e) {
      _file = null;
    }
  }

  void log(String tag, String message) {
    if (!_enabled || _file == null) return;
    final entry =
        '[${DateTime.now().toIso8601String()}] [$tag] $message\n';
    _file!.writeAsString(entry, mode: FileMode.append).ignore();
  }
}
