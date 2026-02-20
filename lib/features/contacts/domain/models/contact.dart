import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/enums/contact_status.dart';

part 'contact.freezed.dart';
part 'contact.g.dart';

/// Hardcoded valid locations for church members
class ContactLocations {
  static const List<String> validLocations = [
    'kanana',
    'majaneng',
    'mashemong',
    'soshanguve',
    'kekana',
  ];

  /// Check if a tag is a valid location
  static bool isValidLocation(String tag) {
    return validLocations.contains(tag.toLowerCase());
  }
}

@freezed
sealed class Contact with _$Contact {
  const Contact._();

  const factory Contact({
    required int id,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    required String phone,
    @Default(ContactStatus.active) ContactStatus status,
    @JsonKey(name: 'opt_out_sms') @Default(false) bool optOutSms,
    @JsonKey(name: 'opt_out_whatsapp') @Default(false) bool optOutWhatsapp,
    @JsonKey(name: 'metadata_')
    String? metadata,
    @Default(false) bool isSynced,
    @Default(false) bool isDeleted,
    int? serverId,
    String? name,
  }) = _Contact;

  factory Contact.fromJson(Map<String, dynamic> json) =>
      _$ContactFromJson(json);

  /// Extract tags from metadata JSON
  List<String> get tags {
    if (metadata == null || metadata!.isEmpty) return [];
    try {
      final Map<String, dynamic> meta = jsonDecode(metadata!);
      if (meta.containsKey('tags') && meta['tags'] is List) {
        return (meta['tags'] as List).map((e) => e.toString()).toList();
      }
    } catch (e) {
      // Invalid JSON, return empty
    }
    return [];
  }

  /// Check if contact has a specific tag
  bool hasTag(String tag) {
    return tags.contains(tag);
  }

  /// Check if contact is eligible for QR code (name != phone AND has 'member' tag)
  bool get isEligibleForQRCode {
    return name != null && name != phone && hasTag('member');
  }

  /// Extract location from metadata tags (excludes 'member' tag)
  /// Returns the location string if found, otherwise null
  String? get location {
    for (final tag in tags) {
      if (tag != 'member' && ContactLocations.isValidLocation(tag)) {
        return tag;
      }
    }
    return null;
  }

  /// Check if contact has a valid location in metadata
  bool get hasLocation => location != null;

  /// Get display name (use name if available, otherwise phone)
  String get displayName => name ?? phone;
}
