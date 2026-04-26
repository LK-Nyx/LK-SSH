import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'data/storage/debug_log_service.dart';
import 'data/storage/json_storage_service.dart';
import 'presentation/screens/server_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Réactiver le log fichier si activé à la session précédente
  try {
    final dir = await getApplicationDocumentsDirectory();
    final dataDir = Directory('${dir.path}/lk_ssh_data');
    final storage = JsonStorageService(dataDir);
    final result = await storage.loadSettings();
    result.when(
      ok: (s) async {
        if (s.fileDebugMode) await DebugLogService.instance.setEnabled(true);
      },
      err: (_) {},
    );
  } catch (_) {}
  runApp(const ProviderScope(child: LkSshApp()));
}

class LkSshApp extends ConsumerWidget {
  const LkSshApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'LK-SSH',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D0D0D),
          foregroundColor: Color(0xFF00FF41),
          elevation: 0,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF41),
          surface: Color(0xFF1A1A1A),
        ),
      ),
      home: const ServerListScreen(),
    );
  }
}
