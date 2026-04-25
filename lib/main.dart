import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/screens/server_list_screen.dart';

void main() {
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
