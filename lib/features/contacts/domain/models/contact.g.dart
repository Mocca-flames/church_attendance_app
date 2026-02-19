// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Contact _$ContactFromJson(Map<String, dynamic> json) => _Contact(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      phone: json['phone'] as String,
      status: $enumDecodeNullable(_$ContactStatusEnumMap, json['status']) ??
          ContactStatus.active,
      optOutSms: json['optOutSms'] as bool? ?? false,
      optOutWhatsapp: json['optOutWhatsapp'] as bool? ?? false,
      metadata: json['metadata_'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      serverId: (json['serverId'] as num?)?.toInt(),
      name: json['name'] as String?,
    );

Map<String, dynamic> _$ContactToJson(_Contact instance) => <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt.toIso8601String(),
      'phone': instance.phone,
      'status': _$ContactStatusEnumMap[instance.status]!,
      'optOutSms': instance.optOutSms,
      'optOutWhatsapp': instance.optOutWhatsapp,
      'metadata_': instance.metadata,
      'isSynced': instance.isSynced,
      'isDeleted': instance.isDeleted,
      'serverId': instance.serverId,
      'name': instance.name,
    };

const _$ContactStatusEnumMap = {
  ContactStatus.active: 'active',
  ContactStatus.inactive: 'inactive',
  ContactStatus.lead: 'lead',
  ContactStatus.customer: 'customer',
};
