import 'package:flutter/material.dart';

import '../../../../core/enums/contact_tag.dart';
import '../../domain/models/contact.dart';

/// Tag Manager Widget for managing contact tags.
///
/// Displays available tags grouped by category:
/// - Role tags (pastor, protocol, worshiper, usher, financier, servant)
/// - Location tags (kanana, majaneng, mashemong, soshanguve, kekana)
/// - Member status as a toggle switch
class TagManager extends StatelessWidget {
  /// The contact whose tags are being managed
  final Contact? contact;

  /// Callback when tags are changed
  final Function(List<String>) onTagsChanged;

  /// Constructor
  const TagManager({
    required this.onTagsChanged,
    super.key,
    this.contact,
    
  });

  /// Get current tags from contact
  List<String> get _currentTags => contact?.tags ?? [];

  /// Check if a tag is currently selected
  bool _isSelected(ContactTag tag) {
    return _currentTags.contains(tag.value);
  }

  /// Handle tag toggle
  void _toggleTag(ContactTag tag) {
    final List<String> newTags = List.from(_currentTags);
    
    if (newTags.contains(tag.value)) {
      newTags.remove(tag.value);
    } else {
      newTags.add(tag.value);
    }
    
    onTagsChanged(newTags);
  }

  /// Handle member toggle
  void _toggleMember(bool value) {
    final List<String> newTags = List.from(_currentTags);
    
    if (value) {
      if (!newTags.contains('member')) {
        newTags.add('member');
      }
    } else {
      newTags.remove('member');
    }
    
    onTagsChanged(newTags);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Member status toggle
        _buildMemberToggle(context),
        
        const SizedBox(height: 16),
        
        // Role tags section
        _buildSectionTitle(context, 'Role Tags', Icons.work),
        const SizedBox(height: 8),
        _buildRoleChips(context),
        
        const SizedBox(height: 16),
        
        // Location tags section
        _buildSectionTitle(context, 'Location Tags', Icons.location_on),
        const SizedBox(height: 8),
        _buildLocationChips(context),
      ],
    );
  }

  /// Build section title
  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build member toggle
  Widget _buildMemberToggle(BuildContext context) {
    final isMember = contact?.isMember ?? false;
    final memberTag = ContactTag.member;
    
    return Card(
      elevation: 0,
      color: isMember 
          ? memberTag.color.withValues(alpha: 0.1)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(
              memberTag.icon,
              color: isMember ? memberTag.color : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(
              memberTag.displayName,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isMember ? memberTag.color : null,
              ),
            ),
          ],
        ),
        subtitle: Text(
          isMember 
              ? 'This contact is a church member'
              : 'Enable to mark as church member',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        value: isMember,
        onChanged: _toggleMember,
        activeThumbColor: memberTag.color,
      ),
    );
  }

  /// Build role tag chips
  Widget _buildRoleChips(BuildContext context) {
    final roleTags = ContactTag.roleTags;
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: roleTags.map((tag) => _buildChip(context, tag)).toList(),
    );
  }

  /// Build location tag chips
  Widget _buildLocationChips(BuildContext context) {
    final locationTags = ContactTag.locationTags;
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: locationTags.map((tag) => _buildChip(context, tag)).toList(),
    );
  }

  /// Build a single chip
  Widget _buildChip(BuildContext context, ContactTag tag) {
    final isSelected = _isSelected(tag);
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tag.icon,
            size: 16,
            color: isSelected ? Colors.white : tag.color,
          ),
          const SizedBox(width: 6),
          Text(
            tag.displayName,
            style: TextStyle(
              color: isSelected ? Colors.white : null,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => _toggleTag(tag),
      selectedColor: tag.color,
      checkmarkColor: Colors.white,
      showCheckmark: false,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      side: BorderSide(
        color: isSelected ? tag.color : Colors.transparent,
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

/// A simpler read-only version that displays tags without editing
class TagDisplay extends StatelessWidget {
  /// The contact whose tags are being displayed
  final Contact contact;
  
  /// Maximum number of tags to display (0 = all)
  final int maxTags;
  
  /// Whether to show role tags
  final bool showRoles;
  
  /// Whether to show location tags
  final bool showLocations;
  
  /// Whether to show member status
  final bool showMember;

  const TagDisplay({
    required this.contact,
    super.key,
    this.maxTags = 0,
    this.showRoles = true,
    this.showLocations = true,
    this.showMember = true,
    
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> tagWidgets = [];
    
    // Add member chip if enabled
    if (showMember && contact.isMember) {
      final memberTag = ContactTag.member;
      tagWidgets.add(_buildTagChip(context, memberTag, true));
    }
    
    // Add role tags
    if (showRoles) {
      for (final roleTag in contact.roleTags) {
        final tag = ContactTag.fromValue(roleTag);
        if (tag != null) {
          tagWidgets.add(_buildTagChip(context, tag, true));
        }
      }
    }
    
    // Add location tags
    if (showLocations) {
      for (final locationTag in contact.locationTags) {
        final tag = ContactTag.fromValue(locationTag);
        if (tag != null) {
          tagWidgets.add(_buildTagChip(context, tag, true));
        }
      }
    }
    
    // Limit tags if maxTags is set
    final displayWidgets = maxTags > 0 && tagWidgets.length > maxTags
        ? tagWidgets.take(maxTags).toList()
        : tagWidgets;
    
    if (displayWidgets.isEmpty) {
      return Text(
        'No tags',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...displayWidgets,
        if (maxTags > 0 && tagWidgets.length > maxTags)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '+${tagWidgets.length - maxTags}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }

  /// Build a single tag chip (read-only)
  Widget _buildTagChip(BuildContext context, ContactTag tag, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected 
            ? tag.color.withValues(alpha: 0.15) 
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tag.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tag.icon,
            size: 14,
            color: tag.color,
          ),
          const SizedBox(width: 4),
          Text(
            tag.displayName,
            style: TextStyle(
              fontSize: 12,
              color: tag.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
