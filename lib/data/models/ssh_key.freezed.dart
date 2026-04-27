// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ssh_key.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SshKey _$SshKeyFromJson(Map<String, dynamic> json) {
  return _SshKey.fromJson(json);
}

/// @nodoc
mixin _$SshKey {
  String get id => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  DateTime get addedAt => throw _privateConstructorUsedError;

  /// Serializes this SshKey to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SshKey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SshKeyCopyWith<SshKey> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SshKeyCopyWith<$Res> {
  factory $SshKeyCopyWith(SshKey value, $Res Function(SshKey) then) =
      _$SshKeyCopyWithImpl<$Res, SshKey>;
  @useResult
  $Res call({String id, String label, DateTime addedAt});
}

/// @nodoc
class _$SshKeyCopyWithImpl<$Res, $Val extends SshKey>
    implements $SshKeyCopyWith<$Res> {
  _$SshKeyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SshKey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? addedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      addedAt: null == addedAt
          ? _value.addedAt
          : addedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SshKeyImplCopyWith<$Res> implements $SshKeyCopyWith<$Res> {
  factory _$$SshKeyImplCopyWith(
          _$SshKeyImpl value, $Res Function(_$SshKeyImpl) then) =
      __$$SshKeyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String label, DateTime addedAt});
}

/// @nodoc
class __$$SshKeyImplCopyWithImpl<$Res>
    extends _$SshKeyCopyWithImpl<$Res, _$SshKeyImpl>
    implements _$$SshKeyImplCopyWith<$Res> {
  __$$SshKeyImplCopyWithImpl(
      _$SshKeyImpl _value, $Res Function(_$SshKeyImpl) _then)
      : super(_value, _then);

  /// Create a copy of SshKey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? addedAt = null,
  }) {
    return _then(_$SshKeyImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      addedAt: null == addedAt
          ? _value.addedAt
          : addedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SshKeyImpl implements _SshKey {
  const _$SshKeyImpl(
      {required this.id, required this.label, required this.addedAt});

  factory _$SshKeyImpl.fromJson(Map<String, dynamic> json) =>
      _$$SshKeyImplFromJson(json);

  @override
  final String id;
  @override
  final String label;
  @override
  final DateTime addedAt;

  @override
  String toString() {
    return 'SshKey(id: $id, label: $label, addedAt: $addedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SshKeyImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.addedAt, addedAt) || other.addedAt == addedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, label, addedAt);

  /// Create a copy of SshKey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SshKeyImplCopyWith<_$SshKeyImpl> get copyWith =>
      __$$SshKeyImplCopyWithImpl<_$SshKeyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SshKeyImplToJson(
      this,
    );
  }
}

abstract class _SshKey implements SshKey {
  const factory _SshKey(
      {required final String id,
      required final String label,
      required final DateTime addedAt}) = _$SshKeyImpl;

  factory _SshKey.fromJson(Map<String, dynamic> json) = _$SshKeyImpl.fromJson;

  @override
  String get id;
  @override
  String get label;
  @override
  DateTime get addedAt;

  /// Create a copy of SshKey
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SshKeyImplCopyWith<_$SshKeyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
