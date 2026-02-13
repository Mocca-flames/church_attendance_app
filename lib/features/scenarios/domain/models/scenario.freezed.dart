// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scenario.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Scenario _$ScenarioFromJson(Map<String, dynamic> json) {
  return _Scenario.fromJson(json);
}

/// @nodoc
mixin _$Scenario {
  int get id => throw _privateConstructorUsedError;
  int? get serverId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  List<String> get filterTags => throw _privateConstructorUsedError;
  ScenarioStatus get status => throw _privateConstructorUsedError;
  int get createdBy => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;
  bool get isSynced => throw _privateConstructorUsedError;
  bool get isDeleted => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ScenarioCopyWith<Scenario> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScenarioCopyWith<$Res> {
  factory $ScenarioCopyWith(Scenario value, $Res Function(Scenario) then) =
      _$ScenarioCopyWithImpl<$Res, Scenario>;
  @useResult
  $Res call(
      {int id,
      int? serverId,
      String name,
      String? description,
      List<String> filterTags,
      ScenarioStatus status,
      int createdBy,
      DateTime createdAt,
      DateTime? completedAt,
      bool isSynced,
      bool isDeleted});
}

/// @nodoc
class _$ScenarioCopyWithImpl<$Res, $Val extends Scenario>
    implements $ScenarioCopyWith<$Res> {
  _$ScenarioCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? serverId = freezed,
    Object? name = null,
    Object? description = freezed,
    Object? filterTags = null,
    Object? status = null,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? completedAt = freezed,
    Object? isSynced = null,
    Object? isDeleted = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      serverId: freezed == serverId
          ? _value.serverId
          : serverId // ignore: cast_nullable_to_non_nullable
              as int?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      filterTags: null == filterTags
          ? _value.filterTags
          : filterTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ScenarioStatus,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScenarioImplCopyWith<$Res>
    implements $ScenarioCopyWith<$Res> {
  factory _$$ScenarioImplCopyWith(
          _$ScenarioImpl value, $Res Function(_$ScenarioImpl) then) =
      __$$ScenarioImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      int? serverId,
      String name,
      String? description,
      List<String> filterTags,
      ScenarioStatus status,
      int createdBy,
      DateTime createdAt,
      DateTime? completedAt,
      bool isSynced,
      bool isDeleted});
}

/// @nodoc
class __$$ScenarioImplCopyWithImpl<$Res>
    extends _$ScenarioCopyWithImpl<$Res, _$ScenarioImpl>
    implements _$$ScenarioImplCopyWith<$Res> {
  __$$ScenarioImplCopyWithImpl(
      _$ScenarioImpl _value, $Res Function(_$ScenarioImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? serverId = freezed,
    Object? name = null,
    Object? description = freezed,
    Object? filterTags = null,
    Object? status = null,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? completedAt = freezed,
    Object? isSynced = null,
    Object? isDeleted = null,
  }) {
    return _then(_$ScenarioImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      serverId: freezed == serverId
          ? _value.serverId
          : serverId // ignore: cast_nullable_to_non_nullable
              as int?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      filterTags: null == filterTags
          ? _value._filterTags
          : filterTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ScenarioStatus,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ScenarioImpl extends _Scenario {
  const _$ScenarioImpl(
      {required this.id,
      this.serverId,
      required this.name,
      this.description,
      required final List<String> filterTags,
      this.status = ScenarioStatus.active,
      required this.createdBy,
      required this.createdAt,
      this.completedAt,
      this.isSynced = false,
      this.isDeleted = false})
      : _filterTags = filterTags,
        super._();

  factory _$ScenarioImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScenarioImplFromJson(json);

  @override
  final int id;
  @override
  final int? serverId;
  @override
  final String name;
  @override
  final String? description;
  final List<String> _filterTags;
  @override
  List<String> get filterTags {
    if (_filterTags is EqualUnmodifiableListView) return _filterTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_filterTags);
  }

  @override
  @JsonKey()
  final ScenarioStatus status;
  @override
  final int createdBy;
  @override
  final DateTime createdAt;
  @override
  final DateTime? completedAt;
  @override
  @JsonKey()
  final bool isSynced;
  @override
  @JsonKey()
  final bool isDeleted;

  @override
  String toString() {
    return 'Scenario(id: $id, serverId: $serverId, name: $name, description: $description, filterTags: $filterTags, status: $status, createdBy: $createdBy, createdAt: $createdAt, completedAt: $completedAt, isSynced: $isSynced, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScenarioImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.serverId, serverId) ||
                other.serverId == serverId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._filterTags, _filterTags) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      serverId,
      name,
      description,
      const DeepCollectionEquality().hash(_filterTags),
      status,
      createdBy,
      createdAt,
      completedAt,
      isSynced,
      isDeleted);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ScenarioImplCopyWith<_$ScenarioImpl> get copyWith =>
      __$$ScenarioImplCopyWithImpl<_$ScenarioImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScenarioImplToJson(
      this,
    );
  }
}

abstract class _Scenario extends Scenario {
  const factory _Scenario(
      {required final int id,
      final int? serverId,
      required final String name,
      final String? description,
      required final List<String> filterTags,
      final ScenarioStatus status,
      required final int createdBy,
      required final DateTime createdAt,
      final DateTime? completedAt,
      final bool isSynced,
      final bool isDeleted}) = _$ScenarioImpl;
  const _Scenario._() : super._();

  factory _Scenario.fromJson(Map<String, dynamic> json) =
      _$ScenarioImpl.fromJson;

  @override
  int get id;
  @override
  int? get serverId;
  @override
  String get name;
  @override
  String? get description;
  @override
  List<String> get filterTags;
  @override
  ScenarioStatus get status;
  @override
  int get createdBy;
  @override
  DateTime get createdAt;
  @override
  DateTime? get completedAt;
  @override
  bool get isSynced;
  @override
  bool get isDeleted;
  @override
  @JsonKey(ignore: true)
  _$$ScenarioImplCopyWith<_$ScenarioImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ScenarioTask _$ScenarioTaskFromJson(Map<String, dynamic> json) {
  return _ScenarioTask.fromJson(json);
}

/// @nodoc
mixin _$ScenarioTask {
  int get id => throw _privateConstructorUsedError;
  int? get serverId => throw _privateConstructorUsedError;
  int get scenarioId => throw _privateConstructorUsedError;
  int get contactId => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;
  int? get completedBy => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;
  bool get isSynced => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ScenarioTaskCopyWith<ScenarioTask> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScenarioTaskCopyWith<$Res> {
  factory $ScenarioTaskCopyWith(
          ScenarioTask value, $Res Function(ScenarioTask) then) =
      _$ScenarioTaskCopyWithImpl<$Res, ScenarioTask>;
  @useResult
  $Res call(
      {int id,
      int? serverId,
      int scenarioId,
      int contactId,
      String phone,
      String? name,
      bool isCompleted,
      int? completedBy,
      DateTime? completedAt,
      bool isSynced});
}

/// @nodoc
class _$ScenarioTaskCopyWithImpl<$Res, $Val extends ScenarioTask>
    implements $ScenarioTaskCopyWith<$Res> {
  _$ScenarioTaskCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? serverId = freezed,
    Object? scenarioId = null,
    Object? contactId = null,
    Object? phone = null,
    Object? name = freezed,
    Object? isCompleted = null,
    Object? completedBy = freezed,
    Object? completedAt = freezed,
    Object? isSynced = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      serverId: freezed == serverId
          ? _value.serverId
          : serverId // ignore: cast_nullable_to_non_nullable
              as int?,
      scenarioId: null == scenarioId
          ? _value.scenarioId
          : scenarioId // ignore: cast_nullable_to_non_nullable
              as int,
      contactId: null == contactId
          ? _value.contactId
          : contactId // ignore: cast_nullable_to_non_nullable
              as int,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      completedBy: freezed == completedBy
          ? _value.completedBy
          : completedBy // ignore: cast_nullable_to_non_nullable
              as int?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScenarioTaskImplCopyWith<$Res>
    implements $ScenarioTaskCopyWith<$Res> {
  factory _$$ScenarioTaskImplCopyWith(
          _$ScenarioTaskImpl value, $Res Function(_$ScenarioTaskImpl) then) =
      __$$ScenarioTaskImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      int? serverId,
      int scenarioId,
      int contactId,
      String phone,
      String? name,
      bool isCompleted,
      int? completedBy,
      DateTime? completedAt,
      bool isSynced});
}

/// @nodoc
class __$$ScenarioTaskImplCopyWithImpl<$Res>
    extends _$ScenarioTaskCopyWithImpl<$Res, _$ScenarioTaskImpl>
    implements _$$ScenarioTaskImplCopyWith<$Res> {
  __$$ScenarioTaskImplCopyWithImpl(
      _$ScenarioTaskImpl _value, $Res Function(_$ScenarioTaskImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? serverId = freezed,
    Object? scenarioId = null,
    Object? contactId = null,
    Object? phone = null,
    Object? name = freezed,
    Object? isCompleted = null,
    Object? completedBy = freezed,
    Object? completedAt = freezed,
    Object? isSynced = null,
  }) {
    return _then(_$ScenarioTaskImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      serverId: freezed == serverId
          ? _value.serverId
          : serverId // ignore: cast_nullable_to_non_nullable
              as int?,
      scenarioId: null == scenarioId
          ? _value.scenarioId
          : scenarioId // ignore: cast_nullable_to_non_nullable
              as int,
      contactId: null == contactId
          ? _value.contactId
          : contactId // ignore: cast_nullable_to_non_nullable
              as int,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      completedBy: freezed == completedBy
          ? _value.completedBy
          : completedBy // ignore: cast_nullable_to_non_nullable
              as int?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ScenarioTaskImpl implements _ScenarioTask {
  const _$ScenarioTaskImpl(
      {required this.id,
      this.serverId,
      required this.scenarioId,
      required this.contactId,
      required this.phone,
      this.name,
      this.isCompleted = false,
      this.completedBy,
      this.completedAt,
      this.isSynced = false});

  factory _$ScenarioTaskImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScenarioTaskImplFromJson(json);

  @override
  final int id;
  @override
  final int? serverId;
  @override
  final int scenarioId;
  @override
  final int contactId;
  @override
  final String phone;
  @override
  final String? name;
  @override
  @JsonKey()
  final bool isCompleted;
  @override
  final int? completedBy;
  @override
  final DateTime? completedAt;
  @override
  @JsonKey()
  final bool isSynced;

  @override
  String toString() {
    return 'ScenarioTask(id: $id, serverId: $serverId, scenarioId: $scenarioId, contactId: $contactId, phone: $phone, name: $name, isCompleted: $isCompleted, completedBy: $completedBy, completedAt: $completedAt, isSynced: $isSynced)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScenarioTaskImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.serverId, serverId) ||
                other.serverId == serverId) &&
            (identical(other.scenarioId, scenarioId) ||
                other.scenarioId == scenarioId) &&
            (identical(other.contactId, contactId) ||
                other.contactId == contactId) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.completedBy, completedBy) ||
                other.completedBy == completedBy) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, serverId, scenarioId,
      contactId, phone, name, isCompleted, completedBy, completedAt, isSynced);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ScenarioTaskImplCopyWith<_$ScenarioTaskImpl> get copyWith =>
      __$$ScenarioTaskImplCopyWithImpl<_$ScenarioTaskImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScenarioTaskImplToJson(
      this,
    );
  }
}

abstract class _ScenarioTask implements ScenarioTask {
  const factory _ScenarioTask(
      {required final int id,
      final int? serverId,
      required final int scenarioId,
      required final int contactId,
      required final String phone,
      final String? name,
      final bool isCompleted,
      final int? completedBy,
      final DateTime? completedAt,
      final bool isSynced}) = _$ScenarioTaskImpl;

  factory _ScenarioTask.fromJson(Map<String, dynamic> json) =
      _$ScenarioTaskImpl.fromJson;

  @override
  int get id;
  @override
  int? get serverId;
  @override
  int get scenarioId;
  @override
  int get contactId;
  @override
  String get phone;
  @override
  String? get name;
  @override
  bool get isCompleted;
  @override
  int? get completedBy;
  @override
  DateTime? get completedAt;
  @override
  bool get isSynced;
  @override
  @JsonKey(ignore: true)
  _$$ScenarioTaskImplCopyWith<_$ScenarioTaskImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ScenarioWithTasks {
  Scenario get scenario => throw _privateConstructorUsedError;
  List<ScenarioTask> get tasks => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ScenarioWithTasksCopyWith<ScenarioWithTasks> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScenarioWithTasksCopyWith<$Res> {
  factory $ScenarioWithTasksCopyWith(
          ScenarioWithTasks value, $Res Function(ScenarioWithTasks) then) =
      _$ScenarioWithTasksCopyWithImpl<$Res, ScenarioWithTasks>;
  @useResult
  $Res call({Scenario scenario, List<ScenarioTask> tasks});

  $ScenarioCopyWith<$Res> get scenario;
}

/// @nodoc
class _$ScenarioWithTasksCopyWithImpl<$Res, $Val extends ScenarioWithTasks>
    implements $ScenarioWithTasksCopyWith<$Res> {
  _$ScenarioWithTasksCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? scenario = null,
    Object? tasks = null,
  }) {
    return _then(_value.copyWith(
      scenario: null == scenario
          ? _value.scenario
          : scenario // ignore: cast_nullable_to_non_nullable
              as Scenario,
      tasks: null == tasks
          ? _value.tasks
          : tasks // ignore: cast_nullable_to_non_nullable
              as List<ScenarioTask>,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ScenarioCopyWith<$Res> get scenario {
    return $ScenarioCopyWith<$Res>(_value.scenario, (value) {
      return _then(_value.copyWith(scenario: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ScenarioWithTasksImplCopyWith<$Res>
    implements $ScenarioWithTasksCopyWith<$Res> {
  factory _$$ScenarioWithTasksImplCopyWith(_$ScenarioWithTasksImpl value,
          $Res Function(_$ScenarioWithTasksImpl) then) =
      __$$ScenarioWithTasksImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Scenario scenario, List<ScenarioTask> tasks});

  @override
  $ScenarioCopyWith<$Res> get scenario;
}

/// @nodoc
class __$$ScenarioWithTasksImplCopyWithImpl<$Res>
    extends _$ScenarioWithTasksCopyWithImpl<$Res, _$ScenarioWithTasksImpl>
    implements _$$ScenarioWithTasksImplCopyWith<$Res> {
  __$$ScenarioWithTasksImplCopyWithImpl(_$ScenarioWithTasksImpl _value,
      $Res Function(_$ScenarioWithTasksImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? scenario = null,
    Object? tasks = null,
  }) {
    return _then(_$ScenarioWithTasksImpl(
      scenario: null == scenario
          ? _value.scenario
          : scenario // ignore: cast_nullable_to_non_nullable
              as Scenario,
      tasks: null == tasks
          ? _value._tasks
          : tasks // ignore: cast_nullable_to_non_nullable
              as List<ScenarioTask>,
    ));
  }
}

/// @nodoc

class _$ScenarioWithTasksImpl extends _ScenarioWithTasks {
  const _$ScenarioWithTasksImpl(
      {required this.scenario, required final List<ScenarioTask> tasks})
      : _tasks = tasks,
        super._();

  @override
  final Scenario scenario;
  final List<ScenarioTask> _tasks;
  @override
  List<ScenarioTask> get tasks {
    if (_tasks is EqualUnmodifiableListView) return _tasks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tasks);
  }

  @override
  String toString() {
    return 'ScenarioWithTasks(scenario: $scenario, tasks: $tasks)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScenarioWithTasksImpl &&
            (identical(other.scenario, scenario) ||
                other.scenario == scenario) &&
            const DeepCollectionEquality().equals(other._tasks, _tasks));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, scenario, const DeepCollectionEquality().hash(_tasks));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ScenarioWithTasksImplCopyWith<_$ScenarioWithTasksImpl> get copyWith =>
      __$$ScenarioWithTasksImplCopyWithImpl<_$ScenarioWithTasksImpl>(
          this, _$identity);
}

abstract class _ScenarioWithTasks extends ScenarioWithTasks {
  const factory _ScenarioWithTasks(
      {required final Scenario scenario,
      required final List<ScenarioTask> tasks}) = _$ScenarioWithTasksImpl;
  const _ScenarioWithTasks._() : super._();

  @override
  Scenario get scenario;
  @override
  List<ScenarioTask> get tasks;
  @override
  @JsonKey(ignore: true)
  _$$ScenarioWithTasksImplCopyWith<_$ScenarioWithTasksImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
