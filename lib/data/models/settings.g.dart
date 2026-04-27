// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SettingsImpl _$$SettingsImplFromJson(Map<String, dynamic> json) =>
    _$SettingsImpl(
      keyStorageMode: $enumDecodeNullable(
              _$KeyStorageModeEnumMap, json['keyStorageMode']) ??
          KeyStorageMode.secureStorage,
      sessionTimeoutMinutes:
          (json['sessionTimeoutMinutes'] as num?)?.toInt() ?? 5,
      theme: $enumDecodeNullable(_$AppThemeEnumMap, json['theme']) ??
          AppTheme.dark,
      verboseLogging: json['verboseLogging'] as bool? ?? false,
      toolbarButtons: (json['toolbarButtons'] as List<dynamic>?)
              ?.map((e) => ToolbarButton.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      fixedNavSection: json['fixedNavSection'] as bool? ?? false,
      terminalFontSize: (json['terminalFontSize'] as num?)?.toDouble() ?? 14.0,
      fileDebugMode: json['fileDebugMode'] as bool? ?? false,
      migrationP1Done: json['migrationP1Done'] as bool? ?? false,
    );

Map<String, dynamic> _$$SettingsImplToJson(_$SettingsImpl instance) =>
    <String, dynamic>{
      'keyStorageMode': _$KeyStorageModeEnumMap[instance.keyStorageMode]!,
      'sessionTimeoutMinutes': instance.sessionTimeoutMinutes,
      'theme': _$AppThemeEnumMap[instance.theme]!,
      'verboseLogging': instance.verboseLogging,
      'toolbarButtons': instance.toolbarButtons,
      'fixedNavSection': instance.fixedNavSection,
      'terminalFontSize': instance.terminalFontSize,
      'fileDebugMode': instance.fileDebugMode,
      'migrationP1Done': instance.migrationP1Done,
    };

const _$KeyStorageModeEnumMap = {
  KeyStorageMode.secureStorage: 'secureStorage',
  KeyStorageMode.passphraseProtected: 'passphraseProtected',
};

const _$AppThemeEnumMap = {
  AppTheme.dark: 'dark',
  AppTheme.light: 'light',
};
