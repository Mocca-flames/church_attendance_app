// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scenario.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Scenario _$ScenarioFromJson(Map<String, dynamic> json) => _Scenario(
      filterTags: (json['filterTags'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      name: json['name'] as String,
      id: (json['id'] as num).toInt(),
      createdBy: (json['createdBy'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      serverId: (json['serverId'] as num?)?.toInt(),
      description: json['description'] as String?,
      status: $enumDecodeNullable(_$ScenarioStatusEnumMap, json['status']) ??
          ScenarioStatus.active,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );

Map<String, dynamic> _$ScenarioToJson(_Scenario instance) => <String, dynamic>{
      'filterTags': instance.filterTags,
      'name': instance.name,
      'id': instance.id,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt.toIso8601String(),
      'serverId': instance.serverId,
      'description': instance.description,
      'status': _$ScenarioStatusEnumMap[instance.status]!,
      'completedAt': instance.completedAt?.toIso8601String(),
      'isSynced': instance.isSynced,
      'isDeleted': instance.isDeleted,
    };

const _$ScenarioStatusEnumMap = {
  ScenarioStatus.active: 'active',
  ScenarioStatus.completed: 'completed',
};

_ScenarioTask _$ScenarioTaskFromJson(Map<String, dynamic> json) =>
    _ScenarioTask(
      id: (json['id'] as num).toInt(),
      scenarioId: (json['scenarioId'] as num).toInt(),
      contactId: (json['contactId'] as num).toInt(),
      phone: json['phone'] as String,
      serverId: (json['serverId'] as num?)?.toInt(),
      name: json['name'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedBy: (json['completedBy'] as num?)?.toInt(),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
    );

Map<String, dynamic> _$ScenarioTaskToJson(_ScenarioTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'scenarioId': instance.scenarioId,
      'contactId': instance.contactId,
      'phone': instance.phone,
      'serverId': instance.serverId,
      'name': instance.name,
      'isCompleted': instance.isCompleted,
      'completedBy': instance.completedBy,
      'completedAt': instance.completedAt?.toIso8601String(),
      'isSynced': instance.isSynced,
    };
