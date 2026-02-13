// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ContactImpl _$$ContactImplFromJson(Map<String, dynamic> json) =>
    _$ContactImpl(
      id: (json['id'] as num).toInt(),
      serverId: (json['serverId'] as num?)?.toInt(),
      name: json['name'] as String?,
      phone: json['phone'] as String,
      status: $enumDecodeNullable(_$ContactStatusEnumMap, json['status']) ??
          ContactStatus.active,
      optOutSms: json['optOutSms'] as bool? ?? false,
      optOutWhatsapp: json['optOutWhatsapp'] as bool? ?? false,
      metadata: json['metadata'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );

Map<String, dynamic> _$$ContactImplToJson(_$ContactImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'serverId': instance.serverId,
      'name': instance.name,
      'phone': instance.phone,
      'status': _$ContactStatusEnumMap[instance.status]!,
      'optOutSms': instance.optOutSms,
      'optOutWhatsapp': instance.optOutWhatsapp,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt.toIso8601String(),
      'isSynced': instance.isSynced,
      'isDeleted': instance.isDeleted,
    };

const _$ContactStatusEnumMap = {
  ContactStatus.active: 'active',
  ContactStatus.inactive: 'inactive',
  ContactStatus.lead: 'lead',
  ContactStatus.customer: 'customer',
};
