import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

enum KeyStorageMode { secureStorage, passphraseProtected }

enum AppTheme { dark, light }

@freezed
class Settings with _$Settings {
  const factory Settings({
    @Default(KeyStorageMode.secureStorage) KeyStorageMode keyStorageMode,
    @Default(5) int sessionTimeoutMinutes,
    @Default(AppTheme.dark) AppTheme theme,
    @Default(false) bool verboseLogging,
  }) = _Settings;

  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);
}
