// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attendance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Attendance {
  int get id;
  int get contactId;
  String get phone;
  ServiceType get serviceType;
  DateTime get serviceDate;
  int get recordedBy;
  DateTime get recordedAt;
  bool get isSynced;
  int? get serverId;

  /// Create a copy of Attendance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AttendanceCopyWith<Attendance> get copyWith =>
      _$AttendanceCopyWithImpl<Attendance>(this as Attendance, _$identity);

  /// Serializes this Attendance to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Attendance &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.contactId, contactId) ||
                other.contactId == contactId) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.serviceType, serviceType) ||
                other.serviceType == serviceType) &&
            (identical(other.serviceDate, serviceDate) ||
                other.serviceDate == serviceDate) &&
            (identical(other.recordedBy, recordedBy) ||
                other.recordedBy == recordedBy) &&
            (identical(other.recordedAt, recordedAt) ||
                other.recordedAt == recordedAt) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced) &&
            (identical(other.serverId, serverId) ||
                other.serverId == serverId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, contactId, phone,
      serviceType, serviceDate, recordedBy, recordedAt, isSynced, serverId);

  @override
  String toString() {
    return 'Attendance(id: $id, contactId: $contactId, phone: $phone, serviceType: $serviceType, serviceDate: $serviceDate, recordedBy: $recordedBy, recordedAt: $recordedAt, isSynced: $isSynced, serverId: $serverId)';
  }
}

/// @nodoc
abstract mixin class $AttendanceCopyWith<$Res> {
  factory $AttendanceCopyWith(
          Attendance value, $Res Function(Attendance) _then) =
      _$AttendanceCopyWithImpl;
  @useResult
  $Res call(
      {int id,
      int contactId,
      String phone,
      ServiceType serviceType,
      DateTime serviceDate,
      int recordedBy,
      DateTime recordedAt,
      bool isSynced,
      int? serverId});
}

/// @nodoc
class _$AttendanceCopyWithImpl<$Res> implements $AttendanceCopyWith<$Res> {
  _$AttendanceCopyWithImpl(this._self, this._then);

  final Attendance _self;
  final $Res Function(Attendance) _then;

  /// Create a copy of Attendance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? contactId = null,
    Object? phone = null,
    Object? serviceType = null,
    Object? serviceDate = null,
    Object? recordedBy = null,
    Object? recordedAt = null,
    Object? isSynced = null,
    Object? serverId = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      contactId: null == contactId
          ? _self.contactId
          : contactId // ignore: cast_nullable_to_non_nullable
              as int,
      phone: null == phone
          ? _self.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      serviceType: null == serviceType
          ? _self.serviceType
          : serviceType // ignore: cast_nullable_to_non_nullable
              as ServiceType,
      serviceDate: null == serviceDate
          ? _self.serviceDate
          : serviceDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      recordedBy: null == recordedBy
          ? _self.recordedBy
          : recordedBy // ignore: cast_nullable_to_non_nullable
              as int,
      recordedAt: null == recordedAt
          ? _self.recordedAt
          : recordedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isSynced: null == isSynced
          ? _self.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
      serverId: freezed == serverId
          ? _self.serverId
          : serverId // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Attendance].
extension AttendancePatterns on Attendance {
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
    TResult Function(_Attendance value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Attendance() when $default != null:
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
    TResult Function(_Attendance value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Attendance():
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
    TResult? Function(_Attendance value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Attendance() when $default != null:
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
            int contactId,
            String phone,
            ServiceType serviceType,
            DateTime serviceDate,
            int recordedBy,
            DateTime recordedAt,
            bool isSynced,
            int? serverId)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Attendance() when $default != null:
        return $default(
            _that.id,
            _that.contactId,
            _that.phone,
            _that.serviceType,
            _that.serviceDate,
            _that.recordedBy,
            _that.recordedAt,
            _that.isSynced,
            _that.serverId);
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
            int contactId,
            String phone,
            ServiceType serviceType,
            DateTime serviceDate,
            int recordedBy,
            DateTime recordedAt,
            bool isSynced,
            int? serverId)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Attendance():
        return $default(
            _that.id,
            _that.contactId,
            _that.phone,
            _that.serviceType,
            _that.serviceDate,
            _that.recordedBy,
            _that.recordedAt,
            _that.isSynced,
            _that.serverId);
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
            int contactId,
            String phone,
            ServiceType serviceType,
            DateTime serviceDate,
            int recordedBy,
            DateTime recordedAt,
            bool isSynced,
            int? serverId)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Attendance() when $default != null:
        return $default(
            _that.id,
            _that.contactId,
            _that.phone,
            _that.serviceType,
            _that.serviceDate,
            _that.recordedBy,
            _that.recordedAt,
            _that.isSynced,
            _that.serverId);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Attendance implements Attendance {
  const _Attendance(
      {required this.id,
      required this.contactId,
      required this.phone,
      required this.serviceType,
      required this.serviceDate,
      required this.recordedBy,
      required this.recordedAt,
      this.isSynced = false,
      this.serverId});
  factory _Attendance.fromJson(Map<String, dynamic> json) =>
      _$AttendanceFromJson(json);

  @override
  final int id;
  @override
  final int contactId;
  @override
  final String phone;
  @override
  final ServiceType serviceType;
  @override
  final DateTime serviceDate;
  @override
  final int recordedBy;
  @override
  final DateTime recordedAt;
  @override
  @JsonKey()
  final bool isSynced;
  @override
  final int? serverId;

  /// Create a copy of Attendance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AttendanceCopyWith<_Attendance> get copyWith =>
      __$AttendanceCopyWithImpl<_Attendance>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AttendanceToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Attendance &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.contactId, contactId) ||
                other.contactId == contactId) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.serviceType, serviceType) ||
                other.serviceType == serviceType) &&
            (identical(other.serviceDate, serviceDate) ||
                other.serviceDate == serviceDate) &&
            (identical(other.recordedBy, recordedBy) ||
                other.recordedBy == recordedBy) &&
            (identical(other.recordedAt, recordedAt) ||
                other.recordedAt == recordedAt) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced) &&
            (identical(other.serverId, serverId) ||
                other.serverId == serverId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, contactId, phone,
      serviceType, serviceDate, recordedBy, recordedAt, isSynced, serverId);

  @override
  String toString() {
    return 'Attendance(id: $id, contactId: $contactId, phone: $phone, serviceType: $serviceType, serviceDate: $serviceDate, recordedBy: $recordedBy, recordedAt: $recordedAt, isSynced: $isSynced, serverId: $serverId)';
  }
}

/// @nodoc
abstract mixin class _$AttendanceCopyWith<$Res>
    implements $AttendanceCopyWith<$Res> {
  factory _$AttendanceCopyWith(
          _Attendance value, $Res Function(_Attendance) _then) =
      __$AttendanceCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int id,
      int contactId,
      String phone,
      ServiceType serviceType,
      DateTime serviceDate,
      int recordedBy,
      DateTime recordedAt,
      bool isSynced,
      int? serverId});
}

/// @nodoc
class __$AttendanceCopyWithImpl<$Res> implements _$AttendanceCopyWith<$Res> {
  __$AttendanceCopyWithImpl(this._self, this._then);

  final _Attendance _self;
  final $Res Function(_Attendance) _then;

  /// Create a copy of Attendance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? contactId = null,
    Object? phone = null,
    Object? serviceType = null,
    Object? serviceDate = null,
    Object? recordedBy = null,
    Object? recordedAt = null,
    Object? isSynced = null,
    Object? serverId = freezed,
  }) {
    return _then(_Attendance(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      contactId: null == contactId
          ? _self.contactId
          : contactId // ignore: cast_nullable_to_non_nullable
              as int,
      phone: null == phone
          ? _self.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      serviceType: null == serviceType
          ? _self.serviceType
          : serviceType // ignore: cast_nullable_to_non_nullable
              as ServiceType,
      serviceDate: null == serviceDate
          ? _self.serviceDate
          : serviceDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      recordedBy: null == recordedBy
          ? _self.recordedBy
          : recordedBy // ignore: cast_nullable_to_non_nullable
              as int,
      recordedAt: null == recordedAt
          ? _self.recordedAt
          : recordedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isSynced: null == isSynced
          ? _self.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
      serverId: freezed == serverId
          ? _self.serverId
          : serverId // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
mixin _$AttendanceRecord {
  Attendance get attendance;
  String? get contactName;

  /// Create a copy of AttendanceRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AttendanceRecordCopyWith<AttendanceRecord> get copyWith =>
      _$AttendanceRecordCopyWithImpl<AttendanceRecord>(
          this as AttendanceRecord, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AttendanceRecord &&
            (identical(other.attendance, attendance) ||
                other.attendance == attendance) &&
            (identical(other.contactName, contactName) ||
                other.contactName == contactName));
  }

  @override
  int get hashCode => Object.hash(runtimeType, attendance, contactName);

  @override
  String toString() {
    return 'AttendanceRecord(attendance: $attendance, contactName: $contactName)';
  }
}

/// @nodoc
abstract mixin class $AttendanceRecordCopyWith<$Res> {
  factory $AttendanceRecordCopyWith(
          AttendanceRecord value, $Res Function(AttendanceRecord) _then) =
      _$AttendanceRecordCopyWithImpl;
  @useResult
  $Res call({Attendance attendance, String? contactName});

  $AttendanceCopyWith<$Res> get attendance;
}

/// @nodoc
class _$AttendanceRecordCopyWithImpl<$Res>
    implements $AttendanceRecordCopyWith<$Res> {
  _$AttendanceRecordCopyWithImpl(this._self, this._then);

  final AttendanceRecord _self;
  final $Res Function(AttendanceRecord) _then;

  /// Create a copy of AttendanceRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? attendance = null,
    Object? contactName = freezed,
  }) {
    return _then(_self.copyWith(
      attendance: null == attendance
          ? _self.attendance
          : attendance // ignore: cast_nullable_to_non_nullable
              as Attendance,
      contactName: freezed == contactName
          ? _self.contactName
          : contactName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of AttendanceRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AttendanceCopyWith<$Res> get attendance {
    return $AttendanceCopyWith<$Res>(_self.attendance, (value) {
      return _then(_self.copyWith(attendance: value));
    });
  }
}

/// Adds pattern-matching-related methods to [AttendanceRecord].
extension AttendanceRecordPatterns on AttendanceRecord {
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
    TResult Function(_AttendanceRecord value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AttendanceRecord() when $default != null:
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
    TResult Function(_AttendanceRecord value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AttendanceRecord():
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
    TResult? Function(_AttendanceRecord value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AttendanceRecord() when $default != null:
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
    TResult Function(Attendance attendance, String? contactName)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AttendanceRecord() when $default != null:
        return $default(_that.attendance, _that.contactName);
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
    TResult Function(Attendance attendance, String? contactName) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AttendanceRecord():
        return $default(_that.attendance, _that.contactName);
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
    TResult? Function(Attendance attendance, String? contactName)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AttendanceRecord() when $default != null:
        return $default(_that.attendance, _that.contactName);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _AttendanceRecord implements AttendanceRecord {
  const _AttendanceRecord({required this.attendance, this.contactName});

  @override
  final Attendance attendance;
  @override
  final String? contactName;

  /// Create a copy of AttendanceRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AttendanceRecordCopyWith<_AttendanceRecord> get copyWith =>
      __$AttendanceRecordCopyWithImpl<_AttendanceRecord>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AttendanceRecord &&
            (identical(other.attendance, attendance) ||
                other.attendance == attendance) &&
            (identical(other.contactName, contactName) ||
                other.contactName == contactName));
  }

  @override
  int get hashCode => Object.hash(runtimeType, attendance, contactName);

  @override
  String toString() {
    return 'AttendanceRecord(attendance: $attendance, contactName: $contactName)';
  }
}

/// @nodoc
abstract mixin class _$AttendanceRecordCopyWith<$Res>
    implements $AttendanceRecordCopyWith<$Res> {
  factory _$AttendanceRecordCopyWith(
          _AttendanceRecord value, $Res Function(_AttendanceRecord) _then) =
      __$AttendanceRecordCopyWithImpl;
  @override
  @useResult
  $Res call({Attendance attendance, String? contactName});

  @override
  $AttendanceCopyWith<$Res> get attendance;
}

/// @nodoc
class __$AttendanceRecordCopyWithImpl<$Res>
    implements _$AttendanceRecordCopyWith<$Res> {
  __$AttendanceRecordCopyWithImpl(this._self, this._then);

  final _AttendanceRecord _self;
  final $Res Function(_AttendanceRecord) _then;

  /// Create a copy of AttendanceRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? attendance = null,
    Object? contactName = freezed,
  }) {
    return _then(_AttendanceRecord(
      attendance: null == attendance
          ? _self.attendance
          : attendance // ignore: cast_nullable_to_non_nullable
              as Attendance,
      contactName: freezed == contactName
          ? _self.contactName
          : contactName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of AttendanceRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AttendanceCopyWith<$Res> get attendance {
    return $AttendanceCopyWith<$Res>(_self.attendance, (value) {
      return _then(_self.copyWith(attendance: value));
    });
  }
}

// dart format on
