// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scenario.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScenarioImpl _$$ScenarioImplFromJson(Map<String, dynamic> json) =>
    _$ScenarioImpl(
      id: (json['id'] as num).toInt(),
      serverId: (json['serverId'] as num?)?.toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      filterTags: (json['filterTags'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      status: $enumDecodeNullable(_$ScenarioStatusEnumMap, json['status']) ??
          ScenarioStatus.active,
      createdBy: (json['createdBy'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );

Map<String, dynamic> _$$ScenarioImplToJson(_$ScenarioImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'serverId': instance.serverId,
      'name': instance.name,
      'description': instance.description,
      'filterTags': instance.filterTags,
      'status': _$ScenarioStatusEnumMap[instance.status]!,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'isSynced': instance.isSynced,
      'isDeleted': instance.isDeleted,
    };

const _$ScenarioStatusEnumMap = {
  ScenarioStatus.active: 'active',
  ScenarioStatus.completed: 'completed',
};

_$ScenarioTaskImpl _$$ScenarioTaskImplFromJson(Map<String, dynamic> json) =>
    _$ScenarioTaskImpl(
      id: (json['id'] as num).toInt(),
      serverId: (json['serverId'] as num?)?.toInt(),
      scenarioId: (json['scenarioId'] as num).toInt(),
      contactId: (json['contactId'] as num).toInt(),
      phone: json['phone'] as String,
      name: json['name'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedBy: (json['completedBy'] as num?)?.toInt(),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
    );

Map<String, dynamic> _$$ScenarioTaskImplToJson(_$ScenarioTaskImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'serverId': instance.serverId,
      'scenarioId': instance.scenarioId,
      'contactId': instance.contactId,
      'phone': instance.phone,
      'name': instance.name,
      'isCompleted': instance.isCompleted,
      'completedBy': instance.completedBy,
      'completedAt': instance.completedAt?.toIso8601String(),
      'isSynced': instance.isSynced,
    };
