// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'toolbar_button.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ToolbarButton _$ToolbarButtonFromJson(Map<String, dynamic> json) {
  return _ToolbarButton.fromJson(json);
}

/// @nodoc
mixin _$ToolbarButton {
  ToolbarButtonType get type => throw _privateConstructorUsedError;
  String? get label => throw _privateConstructorUsedError;

  /// Serializes this ToolbarButton to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ToolbarButton
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ToolbarButtonCopyWith<ToolbarButton> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ToolbarButtonCopyWith<$Res> {
  factory $ToolbarButtonCopyWith(
          ToolbarButton value, $Res Function(ToolbarButton) then) =
      _$ToolbarButtonCopyWithImpl<$Res, ToolbarButton>;
  @useResult
  $Res call({ToolbarButtonType type, String? label});
}

/// @nodoc
class _$ToolbarButtonCopyWithImpl<$Res, $Val extends ToolbarButton>
    implements $ToolbarButtonCopyWith<$Res> {
  _$ToolbarButtonCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ToolbarButton
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? label = freezed,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ToolbarButtonType,
      label: freezed == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ToolbarButtonImplCopyWith<$Res>
    implements $ToolbarButtonCopyWith<$Res> {
  factory _$$ToolbarButtonImplCopyWith(
          _$ToolbarButtonImpl value, $Res Function(_$ToolbarButtonImpl) then) =
      __$$ToolbarButtonImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({ToolbarButtonType type, String? label});
}

/// @nodoc
class __$$ToolbarButtonImplCopyWithImpl<$Res>
    extends _$ToolbarButtonCopyWithImpl<$Res, _$ToolbarButtonImpl>
    implements _$$ToolbarButtonImplCopyWith<$Res> {
  __$$ToolbarButtonImplCopyWithImpl(
      _$ToolbarButtonImpl _value, $Res Function(_$ToolbarButtonImpl) _then)
      : super(_value, _then);

  /// Create a copy of ToolbarButton
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? label = freezed,
  }) {
    return _then(_$ToolbarButtonImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ToolbarButtonType,
      label: freezed == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ToolbarButtonImpl implements _ToolbarButton {
  const _$ToolbarButtonImpl({required this.type, this.label});

  factory _$ToolbarButtonImpl.fromJson(Map<String, dynamic> json) =>
      _$$ToolbarButtonImplFromJson(json);

  @override
  final ToolbarButtonType type;
  @override
  final String? label;

  @override
  String toString() {
    return 'ToolbarButton(type: $type, label: $label)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ToolbarButtonImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.label, label) || other.label == label));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, type, label);

  /// Create a copy of ToolbarButton
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ToolbarButtonImplCopyWith<_$ToolbarButtonImpl> get copyWith =>
      __$$ToolbarButtonImplCopyWithImpl<_$ToolbarButtonImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ToolbarButtonImplToJson(
      this,
    );
  }
}

abstract class _ToolbarButton implements ToolbarButton {
  const factory _ToolbarButton(
      {required final ToolbarButtonType type,
      final String? label}) = _$ToolbarButtonImpl;

  factory _ToolbarButton.fromJson(Map<String, dynamic> json) =
      _$ToolbarButtonImpl.fromJson;

  @override
  ToolbarButtonType get type;
  @override
  String? get label;

  /// Create a copy of ToolbarButton
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ToolbarButtonImplCopyWith<_$ToolbarButtonImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
