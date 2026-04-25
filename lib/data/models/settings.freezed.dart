// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Settings _$SettingsFromJson(Map<String, dynamic> json) {
  return _Settings.fromJson(json);
}

/// @nodoc
mixin _$Settings {
  KeyStorageMode get keyStorageMode => throw _privateConstructorUsedError;
  int get sessionTimeoutMinutes => throw _privateConstructorUsedError;
  AppTheme get theme => throw _privateConstructorUsedError;
  bool get verboseLogging => throw _privateConstructorUsedError;

  /// Serializes this Settings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SettingsCopyWith<Settings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SettingsCopyWith<$Res> {
  factory $SettingsCopyWith(Settings value, $Res Function(Settings) then) =
      _$SettingsCopyWithImpl<$Res, Settings>;
  @useResult
  $Res call(
      {KeyStorageMode keyStorageMode,
      int sessionTimeoutMinutes,
      AppTheme theme,
      bool verboseLogging});
}

/// @nodoc
class _$SettingsCopyWithImpl<$Res, $Val extends Settings>
    implements $SettingsCopyWith<$Res> {
  _$SettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keyStorageMode = null,
    Object? sessionTimeoutMinutes = null,
    Object? theme = null,
    Object? verboseLogging = null,
  }) {
    return _then(_value.copyWith(
      keyStorageMode: null == keyStorageMode
          ? _value.keyStorageMode
          : keyStorageMode // ignore: cast_nullable_to_non_nullable
              as KeyStorageMode,
      sessionTimeoutMinutes: null == sessionTimeoutMinutes
          ? _value.sessionTimeoutMinutes
          : sessionTimeoutMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      theme: null == theme
          ? _value.theme
          : theme // ignore: cast_nullable_to_non_nullable
              as AppTheme,
      verboseLogging: null == verboseLogging
          ? _value.verboseLogging
          : verboseLogging // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SettingsImplCopyWith<$Res>
    implements $SettingsCopyWith<$Res> {
  factory _$$SettingsImplCopyWith(
          _$SettingsImpl value, $Res Function(_$SettingsImpl) then) =
      __$$SettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {KeyStorageMode keyStorageMode,
      int sessionTimeoutMinutes,
      AppTheme theme,
      bool verboseLogging});
}

/// @nodoc
class __$$SettingsImplCopyWithImpl<$Res>
    extends _$SettingsCopyWithImpl<$Res, _$SettingsImpl>
    implements _$$SettingsImplCopyWith<$Res> {
  __$$SettingsImplCopyWithImpl(
      _$SettingsImpl _value, $Res Function(_$SettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keyStorageMode = null,
    Object? sessionTimeoutMinutes = null,
    Object? theme = null,
    Object? verboseLogging = null,
  }) {
    return _then(_$SettingsImpl(
      keyStorageMode: null == keyStorageMode
          ? _value.keyStorageMode
          : keyStorageMode // ignore: cast_nullable_to_non_nullable
              as KeyStorageMode,
      sessionTimeoutMinutes: null == sessionTimeoutMinutes
          ? _value.sessionTimeoutMinutes
          : sessionTimeoutMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      theme: null == theme
          ? _value.theme
          : theme // ignore: cast_nullable_to_non_nullable
              as AppTheme,
      verboseLogging: null == verboseLogging
          ? _value.verboseLogging
          : verboseLogging // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SettingsImpl implements _Settings {
  const _$SettingsImpl(
      {this.keyStorageMode = KeyStorageMode.secureStorage,
      this.sessionTimeoutMinutes = 5,
      this.theme = AppTheme.dark,
      this.verboseLogging = false});

  factory _$SettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$SettingsImplFromJson(json);

  @override
  @JsonKey()
  final KeyStorageMode keyStorageMode;
  @override
  @JsonKey()
  final int sessionTimeoutMinutes;
  @override
  @JsonKey()
  final AppTheme theme;
  @override
  @JsonKey()
  final bool verboseLogging;

  @override
  String toString() {
    return 'Settings(keyStorageMode: $keyStorageMode, sessionTimeoutMinutes: $sessionTimeoutMinutes, theme: $theme, verboseLogging: $verboseLogging)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SettingsImpl &&
            (identical(other.keyStorageMode, keyStorageMode) ||
                other.keyStorageMode == keyStorageMode) &&
            (identical(other.sessionTimeoutMinutes, sessionTimeoutMinutes) ||
                other.sessionTimeoutMinutes == sessionTimeoutMinutes) &&
            (identical(other.theme, theme) || other.theme == theme) &&
            (identical(other.verboseLogging, verboseLogging) ||
                other.verboseLogging == verboseLogging));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, keyStorageMode,
      sessionTimeoutMinutes, theme, verboseLogging);

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SettingsImplCopyWith<_$SettingsImpl> get copyWith =>
      __$$SettingsImplCopyWithImpl<_$SettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SettingsImplToJson(
      this,
    );
  }
}

abstract class _Settings implements Settings {
  const factory _Settings(
      {final KeyStorageMode keyStorageMode,
      final int sessionTimeoutMinutes,
      final AppTheme theme,
      final bool verboseLogging}) = _$SettingsImpl;

  factory _Settings.fromJson(Map<String, dynamic> json) =
      _$SettingsImpl.fromJson;

  @override
  KeyStorageMode get keyStorageMode;
  @override
  int get sessionTimeoutMinutes;
  @override
  AppTheme get theme;
  @override
  bool get verboseLogging;

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SettingsImplCopyWith<_$SettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
