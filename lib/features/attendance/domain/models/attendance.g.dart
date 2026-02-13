// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AttendanceImpl _$$AttendanceImplFromJson(Map<String, dynamic> json) =>
    _$AttendanceImpl(
      id: (json['id'] as num).toInt(),
      serverId: (json['serverId'] as num?)?.toInt(),
      contactId: (json['contactId'] as num).toInt(),
      phone: json['phone'] as String,
      serviceType: $enumDecode(_$ServiceTypeEnumMap, json['serviceType']),
      serviceDate: DateTime.parse(json['serviceDate'] as String),
      recordedBy: (json['recordedBy'] as num).toInt(),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
    );

Map<String, dynamic> _$$AttendanceImplToJson(_$AttendanceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'serverId': instance.serverId,
      'contactId': instance.contactId,
      'phone': instance.phone,
      'serviceType': _$ServiceTypeEnumMap[instance.serviceType]!,
      'serviceDate': instance.serviceDate.toIso8601String(),
      'recordedBy': instance.recordedBy,
      'recordedAt': instance.recordedAt.toIso8601String(),
      'isSynced': instance.isSynced,
    };

const _$ServiceTypeEnumMap = {
  ServiceType.sunday: 'sunday',
  ServiceType.tuesday: 'tuesday',
  ServiceType.specialEvent: 'specialEvent',
};
