import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/contact_tag.dart';
import '../../../../core/services/location_service.dart';
import '../../../../main.dart';
import '../../domain/models/contact.dart';

/// Tag Manager Widget for managing contact tags.
///
/// Displays available tags grouped by category:
/// - Role tags (pastor, protocol, worshiper, usher, financier, servant)
/// - Location tags (from database - supports 20+ locations)
/// - Member status as a toggle switch
///
/// Location selection uses a searchable dropdown for scalability.
class TagManager extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<TagManager> createState() => _TagManagerState();
}

class _TagManagerState extends ConsumerState<TagManager> {
  final TextEditingController _locationSearchController = TextEditingController();
  String? _selectedLocationValue;
  bool _isLoadingLocations = true;
  List<LocationDisplayData> _allLocations = [];
  List<LocationDisplayData> _filteredLocations = [];
  List<String> _recentLocationValues = [];
  String? _defaultLocationValue;

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _loadPreferences();
    // Set initial selected location from contact
    _selectedLocationValue = widget.contact?.location;
  }

  @override
  void dispose() {
    _locationSearchController.dispose();
    super.dispose();
  }

  /// Load user preferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = ref.read(locationPreferencesProvider);
      final recent = prefs.getRecentLocations();
      final defaultLoc = prefs.getDefaultLocation();
      setState(() {
        _recentLocationValues = recent;
        _defaultLocationValue = defaultLoc;
      });
    } catch (_) {
      // Preferences not available
    }
  }

  /// Load locations from the database
  Future<void> _loadLocations() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final locations = await locationService.getAllLocationsAsDisplayData();
      setState(() {
        _allLocations = locations;
        _filteredLocations = locations;
        _isLoadingLocations = false;
      });
    } catch (e) {
      // Fallback to enum-based locations if service fails
      setState(() {
        _allLocations = ContactTag.locationTags
            .map((tag) => LocationDisplayData(
                  value: tag.value,
                  displayName: tag.displayName,
                  color: tag.color,
                  icon: tag.icon,
                ))
            .toList();
        _filteredLocations = _allLocations;
        _isLoadingLocations = false;
      });
    }
  }

  /// Filter locations based on search query
  void _filterLocations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLocations = _allLocations;
      } else {
        _filteredLocations = _allLocations
            .where((loc) =>
                loc.displayName.toLowerCase().contains(query.toLowerCase()) ||
                loc.value.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  /// Get current tags from contact
  List<String> get _currentTags => widget.contact?.tags ?? [];

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

    widget.onTagsChanged(newTags);
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

    widget.onTagsChanged(newTags);
  }

  /// Handle location selection
  void _onLocationSelected(String? value) {
    final List<String> newTags = List.from(_currentTags);

    // Remove any existing location tags
    newTags.removeWhere((tag) =>
        ContactTag.fromValue(tag)?.isLocationTag == true);

    // Add new location if selected
    if (value != null && value.isNotEmpty) {
      newTags.add(value);
      
      // Save to recent locations
      _addToRecentLocations(value);
    }

    setState(() {
      _selectedLocationValue = value;
    });

    widget.onTagsChanged(newTags);
  }

  /// Add location to recent list
  Future<void> _addToRecentLocations(String value) async {
    try {
      final prefs = ref.read(locationPreferencesProvider);
      await prefs.addRecentLocation(value);
      // Reload recent locations
      final recent = prefs.getRecentLocations();
      setState(() {
        _recentLocationValues = recent;
      });
    } catch (_) {
      // Preferences not available
    }
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

        // Location section - searchable dropdown
        _buildSectionTitle(context, 'Location', Icons.location_on),
        const SizedBox(height: 8),
        _buildLocationDropdown(context),
      ],
    );
  }

  /// Build section title
  Widget _buildSectionTitle(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon,
            size: 18, color: Theme.of(context).colorScheme.primary),
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
    final isMember = widget.contact?.isMember ?? false;
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

  /// Build role tag chips (keep as chips - only 6 roles)
  Widget _buildRoleChips(BuildContext context) {
    final roleTags = ContactTag.roleTags;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: roleTags.map((tag) => _buildChip(context, tag)).toList(),
    );
  }

  /// Build searchable location dropdown (scales to 20+ locations)
  Widget _buildLocationDropdown(BuildContext context) {
    if (_isLoadingLocations) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Get the currently selected location display data
    if (_selectedLocationValue != null) {
      try {
      } catch (_) {
        // Location not found in database, try enum fallback
        final enumTag = ContactTag.fromValue(_selectedLocationValue!);
        if (enumTag != null) {
        }
      }
    }

    // Get recent locations display data
    final recentLocations = _recentLocationValues
        .map((value) {
          try {
            return _allLocations.firstWhere((loc) => loc.value == value);
          } catch (_) {
            return null;
          }
        })
        .whereType<LocationDisplayData>()
        .toList();

    // Get default location if no recent and no selection
    LocationDisplayData? defaultLocation;
    if (_selectedLocationValue == null && _defaultLocationValue != null) {
      try {
        defaultLocation = _allLocations.firstWhere(
          (loc) => loc.value == _defaultLocationValue,
        );
      } catch (_) {
        // Not found
      }
    }

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search field
            TextField(
              controller: _locationSearchController,
              decoration: InputDecoration(
                hintText: 'Search location...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _locationSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _locationSearchController.clear();
                          _filterLocations('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: _filterLocations,
            ),

            const Divider(height: 1),

            // Location list (scrollable)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView(
                shrinkWrap: true,
                children: [
                  // "No location" option
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.clear, size: 20),
                    title: const Text('No location'),
                    selected: _selectedLocationValue == null,
                    onTap: () => _onLocationSelected(null),
                  ),

                  // Recent locations section
                  if (_locationSearchController.text.isEmpty &&
                      recentLocations.isNotEmpty) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Text(
                        'Recent',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    ...recentLocations.map((location) => _buildLocationTile(
                          location,
                          _selectedLocationValue == location.value,
                        )),
                  ],

                  // Default location hint (if no recent)
                  if (_locationSearchController.text.isEmpty &&
                      recentLocations.isEmpty &&
                      defaultLocation != null) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Text(
                        'Default',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ),
                    _buildLocationTile(defaultLocation, false),
                  ],

                  // All locations section (when searching or no recent)
                  if (_locationSearchController.text.isNotEmpty ||
                      recentLocations.isEmpty)
                    ..._filteredLocations.map((location) => _buildLocationTile(
                          location,
                          _selectedLocationValue == location.value,
                        )),
                ],
              ),
            ),

            // Show count if filtered
            if (_locationSearchController.text.isNotEmpty &&
                _filteredLocations.length < _allLocations.length)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Showing ${_filteredLocations.length} of ${_allLocations.length} locations',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build a single location list tile
  Widget _buildLocationTile(LocationDisplayData location, bool isSelected) {
    return ListTile(
      dense: true,
      leading: Icon(
        Icons.location_on,
        size: 20,
        color: isSelected ? location.color : Colors.grey,
      ),
      title: Text(location.displayName),
      selected: isSelected,
      selectedTileColor: location.color.withValues(alpha: 0.1),
      onTap: () => _onLocationSelected(location.value),
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
  Widget _buildTagChip(
      BuildContext context, ContactTag tag, bool isSelected) {
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
