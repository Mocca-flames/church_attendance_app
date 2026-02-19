// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Attendance _$AttendanceFromJson(Map<String, dynamic> json) => _Attendance(
      id: (json['id'] as num).toInt(),
      contactId: (json['contactId'] as num).toInt(),
      phone: json['phone'] as String,
      serviceType: $enumDecode(_$ServiceTypeEnumMap, json['serviceType']),
      serviceDate: DateTime.parse(json['serviceDate'] as String),
      recordedBy: (json['recordedBy'] as num).toInt(),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
      serverId: (json['serverId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AttendanceToJson(_Attendance instance) =>
    <String, dynamic>{
      'id': instance.id,
      'contactId': instance.contactId,
      'phone': instance.phone,
      'serviceType': _$ServiceTypeEnumMap[instance.serviceType]!,
      'serviceDate': instance.serviceDate.toIso8601String(),
      'recordedBy': instance.recordedBy,
      'recordedAt': instance.recordedAt.toIso8601String(),
      'isSynced': instance.isSynced,
      'serverId': instance.serverId,
    };

const _$ServiceTypeEnumMap = {
  ServiceType.sunday: 'sunday',
  ServiceType.tuesday: 'tuesday',
  ServiceType.specialEvent: 'specialEvent',
};
