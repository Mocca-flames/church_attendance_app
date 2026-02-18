import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/enums/contact_status.dart';

part 'contact.freezed.dart';
part 'contact.g.dart';

@freezed
class Contact with _$Contact {
  const Contact._();

  const factory Contact({
    required int id,
    required DateTime createdAt,
    required String phone,
    @Default(ContactStatus.active) ContactStatus status,
    @Default(false) bool optOutSms,
    @Default(false) bool optOutWhatsapp,
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

  /// Get display name (use name if available, otherwise phone)
  String get displayName => name ?? phone;
}
