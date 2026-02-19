// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contact.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Contact {
  int get id;
  DateTime get createdAt;
  String get phone;
  ContactStatus get status;
  bool get optOutSms;
  bool get optOutWhatsapp;
  @JsonKey(name: 'metadata_')
  String? get metadata;
  bool get isSynced;
  bool get isDeleted;
  int? get serverId;
  String? get name;

  /// Create a copy of Contact
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ContactCopyWith<Contact> get copyWith =>
      _$ContactCopyWithImpl<Contact>(this as Contact, _$identity);

  /// Serializes this Contact to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Contact &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.optOutSms, optOutSms) ||
                other.optOutSms == optOutSms) &&
            (identical(other.optOutWhatsapp, optOutWhatsapp) ||
                other.optOutWhatsapp == optOutWhatsapp) &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.serverId, serverId) ||
                other.serverId == serverId) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, createdAt, phone, status,
      optOutSms, optOutWhatsapp, metadata, isSynced, isDeleted, serverId, name);

  @override
  String toString() {
    return 'Contact(id: $id, createdAt: $createdAt, phone: $phone, status: $status, optOutSms: $optOutSms, optOutWhatsapp: $optOutWhatsapp, metadata: $metadata, isSynced: $isSynced, isDeleted: $isDeleted, serverId: $serverId, name: $name)';
  }
}

/// @nodoc
abstract mixin class $ContactCopyWith<$Res> {
  factory $ContactCopyWith(Contact value, $Res Function(Contact) _then) =
      _$ContactCopyWithImpl;
  @useResult
  $Res call(
      {int id,
      DateTime createdAt,
      String phone,
      ContactStatus status,
      bool optOutSms,
      bool optOutWhatsapp,
      @JsonKey(name: 'metadata_') String? metadata,
      bool isSynced,
      bool isDeleted,
      int? serverId,
      String? name});
}

/// @nodoc
class _$ContactCopyWithImpl<$Res> implements $ContactCopyWith<$Res> {
  _$ContactCopyWithImpl(this._self, this._then);

  final Contact _self;
  final $Res Function(Contact) _then;

  /// Create a copy of Contact
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? createdAt = null,
    Object? phone = null,
    Object? status = null,
    Object? optOutSms = null,
    Object? optOutWhatsapp = null,
    Object? metadata = freezed,
    Object? isSynced = null,
    Object? isDeleted = null,
    Object? serverId = freezed,
    Object? name = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      phone: null == phone
          ? _self.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as ContactStatus,
      optOutSms: null == optOutSms
          ? _self.optOutSms
          : optOutSms // ignore: cast_nullable_to_non_nullable
              as bool,
      optOutWhatsapp: null == optOutWhatsapp
          ? _self.optOutWhatsapp
          : optOutWhatsapp // ignore: cast_nullable_to_non_nullable
              as bool,
      metadata: freezed == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as String?,
      isSynced: null == isSynced
          ? _self.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
      isDeleted: null == isDeleted
          ? _self.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      serverId: freezed == serverId
          ? _self.serverId
          : serverId // ignore: cast_nullable_to_non_nullable
              as int?,
      name: freezed == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Contact].
extension ContactPatterns on Contact {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_Contact value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Contact() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_Contact value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Contact():
        return $default(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_Contact value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Contact() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            int id,
            DateTime createdAt,
            String phone,
            ContactStatus status,
            bool optOutSms,
            bool optOutWhatsapp,
            @JsonKey(name: 'metadata_') String? metadata,
            bool isSynced,
            bool isDeleted,
            int? serverId,
            String? name)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Contact() when $default != null:
        return $default(
            _that.id,
            _that.createdAt,
            _that.phone,
            _that.status,
            _that.optOutSms,
            _that.optOutWhatsapp,
            _that.metadata,
            _that.isSynced,
            _that.isDeleted,
            _that.serverId,
            _that.name);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            int id,
            DateTime createdAt,
            String phone,
            ContactStatus status,
            bool optOutSms,
            bool optOutWhatsapp,
            @JsonKey(name: 'metadata_') String? metadata,
            bool isSynced,
            bool isDeleted,
            int? serverId,
            String? name)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Contact():
        return $default(
            _that.id,
            _that.createdAt,
            _that.phone,
            _that.status,
            _that.optOutSms,
            _that.optOutWhatsapp,
            _that.metadata,
            _that.isSynced,
            _that.isDeleted,
            _that.serverId,
            _that.name);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            int id,
            DateTime createdAt,
            String phone,
            ContactStatus status,
            bool optOutSms,
            bool optOutWhatsapp,
            @JsonKey(name: 'metadata_') String? metadata,
            bool isSynced,
            bool isDeleted,
            int? serverId,
            String? name)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Contact() when $default != null:
        return $default(
            _that.id,
            _that.createdAt,
            _that.phone,
            _that.status,
            _that.optOutSms,
            _that.optOutWhatsapp,
            _that.metadata,
            _that.isSynced,
            _that.isDeleted,
            _that.serverId,
            _that.name);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Contact extends Contact {
  const _Contact(
      {required this.id,
      required this.createdAt,
      required this.phone,
      this.status = ContactStatus.active,
      this.optOutSms = false,
      this.optOutWhatsapp = false,
      @JsonKey(name: 'metadata_') this.metadata,
      this.isSynced = false,
      this.isDeleted = false,
      this.serverId,
      this.name})
      : super._();
  factory _Contact.fromJson(Map<String, dynamic> json) =>
      _$ContactFromJson(json);

  @override
  final int id;
  @override
  final DateTime createdAt;
  @override
  final String phone;
  @override
  @JsonKey()
  final ContactStatus status;
  @override
  @JsonKey()
  final bool optOutSms;
  @override
  @JsonKey()
  final bool optOutWhatsapp;
  @override
  @JsonKey(name: 'metadata_')
  final String? metadata;
  @override
  @JsonKey()
  final bool isSynced;
  @override
  @JsonKey()
  final bool isDeleted;
  @override
  final int? serverId;
  @override
  final String? name;

  /// Create a copy of Contact
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ContactCopyWith<_Contact> get copyWith =>
      __$ContactCopyWithImpl<_Contact>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ContactToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Contact &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.optOutSms, optOutSms) ||
                other.optOutSms == optOutSms) &&
            (identical(other.optOutWhatsapp, optOutWhatsapp) ||
                other.optOutWhatsapp == optOutWhatsapp) &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.serverId, serverId) ||
                other.serverId == serverId) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, createdAt, phone, status,
      optOutSms, optOutWhatsapp, metadata, isSynced, isDeleted, serverId, name);

  @override
  String toString() {
    return 'Contact(id: $id, createdAt: $createdAt, phone: $phone, status: $status, optOutSms: $optOutSms, optOutWhatsapp: $optOutWhatsapp, metadata: $metadata, isSynced: $isSynced, isDeleted: $isDeleted, serverId: $serverId, name: $name)';
  }
}

/// @nodoc
abstract mixin class _$ContactCopyWith<$Res> implements $ContactCopyWith<$Res> {
  factory _$ContactCopyWith(_Contact value, $Res Function(_Contact) _then) =
      __$ContactCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int id,
      DateTime createdAt,
      String phone,
      ContactStatus status,
      bool optOutSms,
      bool optOutWhatsapp,
      @JsonKey(name: 'metadata_') String? metadata,
      bool isSynced,
      bool isDeleted,
      int? serverId,
      String? name});
}

/// @nodoc
class __$ContactCopyWithImpl<$Res> implements _$ContactCopyWith<$Res> {
  __$ContactCopyWithImpl(this._self, this._then);

  final _Contact _self;
  final $Res Function(_Contact) _then;

  /// Create a copy of Contact
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? createdAt = null,
    Object? phone = null,
    Object? status = null,
    Object? optOutSms = null,
    Object? optOutWhatsapp = null,
    Object? metadata = freezed,
    Object? isSynced = null,
    Object? isDeleted = null,
    Object? serverId = freezed,
    Object? name = freezed,
  }) {
    return _then(_Contact(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      phone: null == phone
          ? _self.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as ContactStatus,
      optOutSms: null == optOutSms
          ? _self.optOutSms
          : optOutSms // ignore: cast_nullable_to_non_nullable
              as bool,
      optOutWhatsapp: null == optOutWhatsapp
          ? _self.optOutWhatsapp
          : optOutWhatsapp // ignore: cast_nullable_to_non_nullable
              as bool,
      metadata: freezed == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as String?,
      isSynced: null == isSynced
          ? _self.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
      isDeleted: null == isDeleted
          ? _self.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      serverId: freezed == serverId
          ? _self.serverId
          : serverId // ignore: cast_nullable_to_non_nullable
              as int?,
      name: freezed == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
