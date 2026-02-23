// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Attendance _$AttendanceFromJson(Map<String, dynamic> json) => _Attendance(
      id: (json['id'] as num).toInt(),
      contactId: (json['contact_id'] as num).toInt(),
      phone: json['phone'] as String,
      serviceType: $enumDecode(_$ServiceTypeEnumMap, json['service_type']),
      serviceDate: DateTime.parse(json['service_date'] as String),
      recordedBy: (json['recorded_by'] as num).toInt(),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
      serverId: (json['serverId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AttendanceToJson(_Attendance instance) =>
    <String, dynamic>{
      'id': instance.id,
      'contact_id': instance.contactId,
      'phone': instance.phone,
      'service_type': _$ServiceTypeEnumMap[instance.serviceType]!,
      'service_date': instance.serviceDate.toIso8601String(),
      'recorded_by': instance.recordedBy,
      'recorded_at': instance.recordedAt.toIso8601String(),
      'isSynced': instance.isSynced,
      'serverId': instance.serverId,
    };

const _$ServiceTypeEnumMap = {
  ServiceType.sunday: 'sunday',
  ServiceType.tuesday: 'tuesday',
  ServiceType.specialEvent: 'specialEvent',
};
