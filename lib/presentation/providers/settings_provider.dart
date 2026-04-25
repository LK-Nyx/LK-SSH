import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/settings.dart';
import 'storage_provider.dart';

part 'settings_provider.g.dart';

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  @override
  Future<Settings> build() async {
    final storage = await ref.watch(storageProvider.future);
    final result = await storage.loadSettings();
    return result.when(ok: (s) => s, err: (_) => const Settings());
  }

  Future<void> save(Settings settings) async {
    final storage = await ref.read(storageProvider.future);
    await storage.saveSettings(settings);
    state = AsyncData(settings);
  }
}
