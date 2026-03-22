// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scenario.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Scenario {

 List<String> get filterTags; String get name; int get id; int get createdBy; DateTime get createdAt; int? get serverId; String? get description; ScenarioStatus get status; DateTime? get completedAt; bool get isSynced; bool get isDeleted;
/// Create a copy of Scenario
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScenarioCopyWith<Scenario> get copyWith => _$ScenarioCopyWithImpl<Scenario>(this as Scenario, _$identity);

  /// Serializes this Scenario to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Scenario&&const DeepCollectionEquality().equals(other.filterTags, filterTags)&&(identical(other.name, name) || other.name == name)&&(identical(other.id, id) || other.id == id)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.serverId, serverId) || other.serverId == serverId)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(filterTags),name,id,createdBy,createdAt,serverId,description,status,completedAt,isSynced,isDeleted);

@override
String toString() {
  return 'Scenario(filterTags: $filterTags, name: $name, id: $id, createdBy: $createdBy, createdAt: $createdAt, serverId: $serverId, description: $description, status: $status, completedAt: $completedAt, isSynced: $isSynced, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class $ScenarioCopyWith<$Res>  {
  factory $ScenarioCopyWith(Scenario value, $Res Function(Scenario) _then) = _$ScenarioCopyWithImpl;
@useResult
$Res call({
 List<String> filterTags, String name, int id, int createdBy, DateTime createdAt, int? serverId, String? description, ScenarioStatus status, DateTime? completedAt, bool isSynced, bool isDeleted
});




}
/// @nodoc
class _$ScenarioCopyWithImpl<$Res>
    implements $ScenarioCopyWith<$Res> {
  _$ScenarioCopyWithImpl(this._self, this._then);

  final Scenario _self;
  final $Res Function(Scenario) _then;

/// Create a copy of Scenario
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? filterTags = null,Object? name = null,Object? id = null,Object? createdBy = null,Object? createdAt = null,Object? serverId = freezed,Object? description = freezed,Object? status = null,Object? completedAt = freezed,Object? isSynced = null,Object? isDeleted = null,}) {
  return _then(_self.copyWith(
filterTags: null == filterTags ? _self.filterTags : filterTags // ignore: cast_nullable_to_non_nullable
as List<String>,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,serverId: freezed == serverId ? _self.serverId : serverId // ignore: cast_nullable_to_non_nullable
as int?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ScenarioStatus,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Scenario].
extension ScenarioPatterns on Scenario {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Scenario value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Scenario() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Scenario value)  $default,){
final _that = this;
switch (_that) {
case _Scenario():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Scenario value)?  $default,){
final _that = this;
switch (_that) {
case _Scenario() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> filterTags,  String name,  int id,  int createdBy,  DateTime createdAt,  int? serverId,  String? description,  ScenarioStatus status,  DateTime? completedAt,  bool isSynced,  bool isDeleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Scenario() when $default != null:
return $default(_that.filterTags,_that.name,_that.id,_that.createdBy,_that.createdAt,_that.serverId,_that.description,_that.status,_that.completedAt,_that.isSynced,_that.isDeleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> filterTags,  String name,  int id,  int createdBy,  DateTime createdAt,  int? serverId,  String? description,  ScenarioStatus status,  DateTime? completedAt,  bool isSynced,  bool isDeleted)  $default,) {final _that = this;
switch (_that) {
case _Scenario():
return $default(_that.filterTags,_that.name,_that.id,_that.createdBy,_that.createdAt,_that.serverId,_that.description,_that.status,_that.completedAt,_that.isSynced,_that.isDeleted);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> filterTags,  String name,  int id,  int createdBy,  DateTime createdAt,  int? serverId,  String? description,  ScenarioStatus status,  DateTime? completedAt,  bool isSynced,  bool isDeleted)?  $default,) {final _that = this;
switch (_that) {
case _Scenario() when $default != null:
return $default(_that.filterTags,_that.name,_that.id,_that.createdBy,_that.createdAt,_that.serverId,_that.description,_that.status,_that.completedAt,_that.isSynced,_that.isDeleted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Scenario extends Scenario {
  const _Scenario({required final  List<String> filterTags, required this.name, required this.id, required this.createdBy, required this.createdAt, this.serverId, this.description, this.status = ScenarioStatus.active, this.completedAt, this.isSynced = false, this.isDeleted = false}): _filterTags = filterTags,super._();
  factory _Scenario.fromJson(Map<String, dynamic> json) => _$ScenarioFromJson(json);

 final  List<String> _filterTags;
@override List<String> get filterTags {
  if (_filterTags is EqualUnmodifiableListView) return _filterTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_filterTags);
}

@override final  String name;
@override final  int id;
@override final  int createdBy;
@override final  DateTime createdAt;
@override final  int? serverId;
@override final  String? description;
@override@JsonKey() final  ScenarioStatus status;
@override final  DateTime? completedAt;
@override@JsonKey() final  bool isSynced;
@override@JsonKey() final  bool isDeleted;

/// Create a copy of Scenario
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScenarioCopyWith<_Scenario> get copyWith => __$ScenarioCopyWithImpl<_Scenario>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScenarioToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Scenario&&const DeepCollectionEquality().equals(other._filterTags, _filterTags)&&(identical(other.name, name) || other.name == name)&&(identical(other.id, id) || other.id == id)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.serverId, serverId) || other.serverId == serverId)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_filterTags),name,id,createdBy,createdAt,serverId,description,status,completedAt,isSynced,isDeleted);

@override
String toString() {
  return 'Scenario(filterTags: $filterTags, name: $name, id: $id, createdBy: $createdBy, createdAt: $createdAt, serverId: $serverId, description: $description, status: $status, completedAt: $completedAt, isSynced: $isSynced, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class _$ScenarioCopyWith<$Res> implements $ScenarioCopyWith<$Res> {
  factory _$ScenarioCopyWith(_Scenario value, $Res Function(_Scenario) _then) = __$ScenarioCopyWithImpl;
@override @useResult
$Res call({
 List<String> filterTags, String name, int id, int createdBy, DateTime createdAt, int? serverId, String? description, ScenarioStatus status, DateTime? completedAt, bool isSynced, bool isDeleted
});




}
/// @nodoc
class __$ScenarioCopyWithImpl<$Res>
    implements _$ScenarioCopyWith<$Res> {
  __$ScenarioCopyWithImpl(this._self, this._then);

  final _Scenario _self;
  final $Res Function(_Scenario) _then;

/// Create a copy of Scenario
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? filterTags = null,Object? name = null,Object? id = null,Object? createdBy = null,Object? createdAt = null,Object? serverId = freezed,Object? description = freezed,Object? status = null,Object? completedAt = freezed,Object? isSynced = null,Object? isDeleted = null,}) {
  return _then(_Scenario(
filterTags: null == filterTags ? _self._filterTags : filterTags // ignore: cast_nullable_to_non_nullable
as List<String>,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,serverId: freezed == serverId ? _self.serverId : serverId // ignore: cast_nullable_to_non_nullable
as int?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ScenarioStatus,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ScenarioTask {

 int get id; int get scenarioId; int get contactId; String get phone; int? get serverId; String? get name; bool get isCompleted; int? get completedBy; DateTime? get completedAt; bool get isSynced; String? get notes; DateTime? get dueDate; String get priority;
/// Create a copy of ScenarioTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScenarioTaskCopyWith<ScenarioTask> get copyWith => _$ScenarioTaskCopyWithImpl<ScenarioTask>(this as ScenarioTask, _$identity);

  /// Serializes this ScenarioTask to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScenarioTask&&(identical(other.id, id) || other.id == id)&&(identical(other.scenarioId, scenarioId) || other.scenarioId == scenarioId)&&(identical(other.contactId, contactId) || other.contactId == contactId)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.serverId, serverId) || other.serverId == serverId)&&(identical(other.name, name) || other.name == name)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.completedBy, completedBy) || other.completedBy == completedBy)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.priority, priority) || other.priority == priority));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,scenarioId,contactId,phone,serverId,name,isCompleted,completedBy,completedAt,isSynced,notes,dueDate,priority);

@override
String toString() {
  return 'ScenarioTask(id: $id, scenarioId: $scenarioId, contactId: $contactId, phone: $phone, serverId: $serverId, name: $name, isCompleted: $isCompleted, completedBy: $completedBy, completedAt: $completedAt, isSynced: $isSynced, notes: $notes, dueDate: $dueDate, priority: $priority)';
}


}

/// @nodoc
abstract mixin class $ScenarioTaskCopyWith<$Res>  {
  factory $ScenarioTaskCopyWith(ScenarioTask value, $Res Function(ScenarioTask) _then) = _$ScenarioTaskCopyWithImpl;
@useResult
$Res call({
 int id, int scenarioId, int contactId, String phone, int? serverId, String? name, bool isCompleted, int? completedBy, DateTime? completedAt, bool isSynced, String? notes, DateTime? dueDate, String priority
});




}
/// @nodoc
class _$ScenarioTaskCopyWithImpl<$Res>
    implements $ScenarioTaskCopyWith<$Res> {
  _$ScenarioTaskCopyWithImpl(this._self, this._then);

  final ScenarioTask _self;
  final $Res Function(ScenarioTask) _then;

/// Create a copy of ScenarioTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? scenarioId = null,Object? contactId = null,Object? phone = null,Object? serverId = freezed,Object? name = freezed,Object? isCompleted = null,Object? completedBy = freezed,Object? completedAt = freezed,Object? isSynced = null,Object? notes = freezed,Object? dueDate = freezed,Object? priority = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,scenarioId: null == scenarioId ? _self.scenarioId : scenarioId // ignore: cast_nullable_to_non_nullable
as int,contactId: null == contactId ? _self.contactId : contactId // ignore: cast_nullable_to_non_nullable
as int,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,serverId: freezed == serverId ? _self.serverId : serverId // ignore: cast_nullable_to_non_nullable
as int?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,completedBy: freezed == completedBy ? _self.completedBy : completedBy // ignore: cast_nullable_to_non_nullable
as int?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ScenarioTask].
extension ScenarioTaskPatterns on ScenarioTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScenarioTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScenarioTask() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScenarioTask value)  $default,){
final _that = this;
switch (_that) {
case _ScenarioTask():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScenarioTask value)?  $default,){
final _that = this;
switch (_that) {
case _ScenarioTask() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int scenarioId,  int contactId,  String phone,  int? serverId,  String? name,  bool isCompleted,  int? completedBy,  DateTime? completedAt,  bool isSynced,  String? notes,  DateTime? dueDate,  String priority)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScenarioTask() when $default != null:
return $default(_that.id,_that.scenarioId,_that.contactId,_that.phone,_that.serverId,_that.name,_that.isCompleted,_that.completedBy,_that.completedAt,_that.isSynced,_that.notes,_that.dueDate,_that.priority);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int scenarioId,  int contactId,  String phone,  int? serverId,  String? name,  bool isCompleted,  int? completedBy,  DateTime? completedAt,  bool isSynced,  String? notes,  DateTime? dueDate,  String priority)  $default,) {final _that = this;
switch (_that) {
case _ScenarioTask():
return $default(_that.id,_that.scenarioId,_that.contactId,_that.phone,_that.serverId,_that.name,_that.isCompleted,_that.completedBy,_that.completedAt,_that.isSynced,_that.notes,_that.dueDate,_that.priority);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int scenarioId,  int contactId,  String phone,  int? serverId,  String? name,  bool isCompleted,  int? completedBy,  DateTime? completedAt,  bool isSynced,  String? notes,  DateTime? dueDate,  String priority)?  $default,) {final _that = this;
switch (_that) {
case _ScenarioTask() when $default != null:
return $default(_that.id,_that.scenarioId,_that.contactId,_that.phone,_that.serverId,_that.name,_that.isCompleted,_that.completedBy,_that.completedAt,_that.isSynced,_that.notes,_that.dueDate,_that.priority);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScenarioTask implements ScenarioTask {
  const _ScenarioTask({required this.id, required this.scenarioId, required this.contactId, required this.phone, this.serverId, this.name, this.isCompleted = false, this.completedBy, this.completedAt, this.isSynced = false, this.notes, this.dueDate, this.priority = 'medium'});
  factory _ScenarioTask.fromJson(Map<String, dynamic> json) => _$ScenarioTaskFromJson(json);

@override final  int id;
@override final  int scenarioId;
@override final  int contactId;
@override final  String phone;
@override final  int? serverId;
@override final  String? name;
@override@JsonKey() final  bool isCompleted;
@override final  int? completedBy;
@override final  DateTime? completedAt;
@override@JsonKey() final  bool isSynced;
@override final  String? notes;
@override final  DateTime? dueDate;
@override@JsonKey() final  String priority;

/// Create a copy of ScenarioTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScenarioTaskCopyWith<_ScenarioTask> get copyWith => __$ScenarioTaskCopyWithImpl<_ScenarioTask>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScenarioTaskToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScenarioTask&&(identical(other.id, id) || other.id == id)&&(identical(other.scenarioId, scenarioId) || other.scenarioId == scenarioId)&&(identical(other.contactId, contactId) || other.contactId == contactId)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.serverId, serverId) || other.serverId == serverId)&&(identical(other.name, name) || other.name == name)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.completedBy, completedBy) || other.completedBy == completedBy)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.priority, priority) || other.priority == priority));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,scenarioId,contactId,phone,serverId,name,isCompleted,completedBy,completedAt,isSynced,notes,dueDate,priority);

@override
String toString() {
  return 'ScenarioTask(id: $id, scenarioId: $scenarioId, contactId: $contactId, phone: $phone, serverId: $serverId, name: $name, isCompleted: $isCompleted, completedBy: $completedBy, completedAt: $completedAt, isSynced: $isSynced, notes: $notes, dueDate: $dueDate, priority: $priority)';
}


}

/// @nodoc
abstract mixin class _$ScenarioTaskCopyWith<$Res> implements $ScenarioTaskCopyWith<$Res> {
  factory _$ScenarioTaskCopyWith(_ScenarioTask value, $Res Function(_ScenarioTask) _then) = __$ScenarioTaskCopyWithImpl;
@override @useResult
$Res call({
 int id, int scenarioId, int contactId, String phone, int? serverId, String? name, bool isCompleted, int? completedBy, DateTime? completedAt, bool isSynced, String? notes, DateTime? dueDate, String priority
});




}
/// @nodoc
class __$ScenarioTaskCopyWithImpl<$Res>
    implements _$ScenarioTaskCopyWith<$Res> {
  __$ScenarioTaskCopyWithImpl(this._self, this._then);

  final _ScenarioTask _self;
  final $Res Function(_ScenarioTask) _then;

/// Create a copy of ScenarioTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? scenarioId = null,Object? contactId = null,Object? phone = null,Object? serverId = freezed,Object? name = freezed,Object? isCompleted = null,Object? completedBy = freezed,Object? completedAt = freezed,Object? isSynced = null,Object? notes = freezed,Object? dueDate = freezed,Object? priority = null,}) {
  return _then(_ScenarioTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,scenarioId: null == scenarioId ? _self.scenarioId : scenarioId // ignore: cast_nullable_to_non_nullable
as int,contactId: null == contactId ? _self.contactId : contactId // ignore: cast_nullable_to_non_nullable
as int,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,serverId: freezed == serverId ? _self.serverId : serverId // ignore: cast_nullable_to_non_nullable
as int?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,completedBy: freezed == completedBy ? _self.completedBy : completedBy // ignore: cast_nullable_to_non_nullable
as int?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ScenarioWithTasks {

 Scenario get scenario; List<ScenarioTask> get tasks;
/// Create a copy of ScenarioWithTasks
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScenarioWithTasksCopyWith<ScenarioWithTasks> get copyWith => _$ScenarioWithTasksCopyWithImpl<ScenarioWithTasks>(this as ScenarioWithTasks, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScenarioWithTasks&&(identical(other.scenario, scenario) || other.scenario == scenario)&&const DeepCollectionEquality().equals(other.tasks, tasks));
}


@override
int get hashCode => Object.hash(runtimeType,scenario,const DeepCollectionEquality().hash(tasks));

@override
String toString() {
  return 'ScenarioWithTasks(scenario: $scenario, tasks: $tasks)';
}


}

/// @nodoc
abstract mixin class $ScenarioWithTasksCopyWith<$Res>  {
  factory $ScenarioWithTasksCopyWith(ScenarioWithTasks value, $Res Function(ScenarioWithTasks) _then) = _$ScenarioWithTasksCopyWithImpl;
@useResult
$Res call({
 Scenario scenario, List<ScenarioTask> tasks
});


$ScenarioCopyWith<$Res> get scenario;

}
/// @nodoc
class _$ScenarioWithTasksCopyWithImpl<$Res>
    implements $ScenarioWithTasksCopyWith<$Res> {
  _$ScenarioWithTasksCopyWithImpl(this._self, this._then);

  final ScenarioWithTasks _self;
  final $Res Function(ScenarioWithTasks) _then;

/// Create a copy of ScenarioWithTasks
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? scenario = null,Object? tasks = null,}) {
  return _then(_self.copyWith(
scenario: null == scenario ? _self.scenario : scenario // ignore: cast_nullable_to_non_nullable
as Scenario,tasks: null == tasks ? _self.tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<ScenarioTask>,
  ));
}
/// Create a copy of ScenarioWithTasks
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScenarioCopyWith<$Res> get scenario {
  
  return $ScenarioCopyWith<$Res>(_self.scenario, (value) {
    return _then(_self.copyWith(scenario: value));
  });
}
}


/// Adds pattern-matching-related methods to [ScenarioWithTasks].
extension ScenarioWithTasksPatterns on ScenarioWithTasks {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScenarioWithTasks value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScenarioWithTasks() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScenarioWithTasks value)  $default,){
final _that = this;
switch (_that) {
case _ScenarioWithTasks():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScenarioWithTasks value)?  $default,){
final _that = this;
switch (_that) {
case _ScenarioWithTasks() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Scenario scenario,  List<ScenarioTask> tasks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScenarioWithTasks() when $default != null:
return $default(_that.scenario,_that.tasks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Scenario scenario,  List<ScenarioTask> tasks)  $default,) {final _that = this;
switch (_that) {
case _ScenarioWithTasks():
return $default(_that.scenario,_that.tasks);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Scenario scenario,  List<ScenarioTask> tasks)?  $default,) {final _that = this;
switch (_that) {
case _ScenarioWithTasks() when $default != null:
return $default(_that.scenario,_that.tasks);case _:
  return null;

}
}

}

/// @nodoc


class _ScenarioWithTasks extends ScenarioWithTasks {
  const _ScenarioWithTasks({required this.scenario, required final  List<ScenarioTask> tasks}): _tasks = tasks,super._();
  

@override final  Scenario scenario;
 final  List<ScenarioTask> _tasks;
@override List<ScenarioTask> get tasks {
  if (_tasks is EqualUnmodifiableListView) return _tasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tasks);
}


/// Create a copy of ScenarioWithTasks
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScenarioWithTasksCopyWith<_ScenarioWithTasks> get copyWith => __$ScenarioWithTasksCopyWithImpl<_ScenarioWithTasks>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScenarioWithTasks&&(identical(other.scenario, scenario) || other.scenario == scenario)&&const DeepCollectionEquality().equals(other._tasks, _tasks));
}


@override
int get hashCode => Object.hash(runtimeType,scenario,const DeepCollectionEquality().hash(_tasks));

@override
String toString() {
  return 'ScenarioWithTasks(scenario: $scenario, tasks: $tasks)';
}


}

/// @nodoc
abstract mixin class _$ScenarioWithTasksCopyWith<$Res> implements $ScenarioWithTasksCopyWith<$Res> {
  factory _$ScenarioWithTasksCopyWith(_ScenarioWithTasks value, $Res Function(_ScenarioWithTasks) _then) = __$ScenarioWithTasksCopyWithImpl;
@override @useResult
$Res call({
 Scenario scenario, List<ScenarioTask> tasks
});


@override $ScenarioCopyWith<$Res> get scenario;

}
/// @nodoc
class __$ScenarioWithTasksCopyWithImpl<$Res>
    implements _$ScenarioWithTasksCopyWith<$Res> {
  __$ScenarioWithTasksCopyWithImpl(this._self, this._then);

  final _ScenarioWithTasks _self;
  final $Res Function(_ScenarioWithTasks) _then;

/// Create a copy of ScenarioWithTasks
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? scenario = null,Object? tasks = null,}) {
  return _then(_ScenarioWithTasks(
scenario: null == scenario ? _self.scenario : scenario // ignore: cast_nullable_to_non_nullable
as Scenario,tasks: null == tasks ? _self._tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<ScenarioTask>,
  ));
}

/// Create a copy of ScenarioWithTasks
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScenarioCopyWith<$Res> get scenario {
  
  return $ScenarioCopyWith<$Res>(_self.scenario, (value) {
    return _then(_self.copyWith(scenario: value));
  });
}
}

// dart format on
