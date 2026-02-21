import 'package:flutter/material.dart';

/// Enum for contact tags with display information.
/// 
/// Categories:
/// - Role tags: pastor, protocol, worshiper, usher, financier, servant
/// - Member status: member
/// - Location tags: kanana, majaneng, mashemong, soshanguve, kekana
/// 
/// Important: Location and Member are NOT roles - they are separate categories.
enum ContactTag {
  // Role tags - ministry/position in church
  pastor('pastor', 'Pastor', Icons.church, Color(0xFF9C27B0)),
  protocol('protocol', 'Protocol', Icons.event_note, Color(0xFF2196F3)),
  worshiper('worshiper', 'Worshiper', Icons.volunteer_activism, Color(0xFF4CAF50)),
  usher('usher', 'Usher', Icons.door_front_door_outlined, Color(0xFFFF9800)),
  financier('financier', 'Finance', Icons.account_balance, Color(0xFF009688)),
  servant('servant', 'Servant', Icons.handshake, Color(0xFF3F51B5)),
  
  // Membership status
  member('member', 'Member', Icons.card_membership, Color(0xFF8BC34A)),
  
  // Location tags (geographic areas)
  kanana('kanana', 'Kanana', Icons.location_on, Color(0xFFF44336)),
  majaneng('majaneng', 'Majaneng', Icons.location_on, Color(0xFFF44336)),
  mashemong('mashemong', 'Mashemong', Icons.location_on, Color(0xFFF44336)),
  soshanguve('soshanguve', 'Soshanguve', Icons.location_on, Color(0xFFF44336)),
  kekana('kekana', 'Kekana', Icons.location_on, Color(0xFFF44336));

  const ContactTag(this.value, this.displayName, this.icon, this.color);

  /// The value stored in metadata
  final String value;
  
  /// Human-readable display name
  final String displayName;
  
  /// Icon representing this tag
  final IconData icon;
  
  /// Color for this tag
  final Color color;

  /// Get all role tags
  static List<ContactTag> get roleTags => [
    pastor, protocol, worshiper, usher, financier, servant
  ];

  /// Get all location tags
  static List<ContactTag> get locationTags => [
    kanana, majaneng, mashemong, soshanguve, kekana
  ];

  /// Get tag by value
  static ContactTag? fromValue(String value) {
    try {
      return ContactTag.values.firstWhere((tag) => tag.value == value.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  /// Check if this tag is a role tag
  bool get isRoleTag => roleTags.contains(this);

  /// Check if this tag is a location tag
  bool get isLocationTag => locationTags.contains(this);

  /// Check if this tag is the member tag
  bool get isMemberTag => this == member;
}
