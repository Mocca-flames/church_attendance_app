import 'dart:math';

import 'package:church_attendance_app/core/constants/app_colors.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/constants/app_typography.dart';
import 'package:church_attendance_app/core/enums/contact_tag.dart';
import 'package:church_attendance_app/core/services/location_service.dart';
import 'package:church_attendance_app/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const Set<String> _hardcodedLocations = {
  'kanana',
  'majaneng',
  'mashemong',
  'soshanguve',
  'kekana',
};

class LocationSelector extends ConsumerStatefulWidget {
  final String? selectedLocation;
  final ValueChanged<String?> onLocationSelected;
  final VoidCallback? onLocationCreated;
  final bool compact;
  final bool showDeleteOption;
  final int? refreshKey;

  const LocationSelector({
    required this.onLocationSelected,
    super.key,
    this.selectedLocation,
    this.onLocationCreated,
    this.compact = false,
    this.showDeleteOption = false,
    this.refreshKey,
  });

  @override
  ConsumerState<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends ConsumerState<LocationSelector> {
  final _searchController = TextEditingController();
  List<LocationDisplayData> _allLocations = [];
  List<LocationDisplayData> _filteredLocations = [];
  bool _isLoading = true;
  String? _locationToDelete;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LocationSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshKey != oldWidget.refreshKey) {
      _loadLocations();
    }
  }

  Future<void> _loadLocations() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final dbLocations = await locationService.getAllLocationsAsDisplayData();

      final hardcoded = ContactTag.locationTags
          .map(
            (tag) => LocationDisplayData(
              value: tag.value,
              displayName: tag.displayName,
              color: tag.color,
              icon: tag.icon,
            ),
          )
          .toList();

      final hardcodedValues = hardcoded
          .map((l) => l.value.toLowerCase())
          .toSet();

      final dynamicLocations = dbLocations
          .where((loc) => !hardcodedValues.contains(loc.value.toLowerCase()))
          .toList();

      final combined = [...hardcoded, ...dynamicLocations];

      combined.sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );

      setState(() {
        _allLocations = combined;
        _filteredLocations = combined;
        _isLoading = false;
      });
    } catch (e) {
      final fallback = ContactTag.locationTags
          .map(
            (tag) => LocationDisplayData(
              value: tag.value,
              displayName: tag.displayName,
              color: tag.color,
              icon: tag.icon,
            ),
          )
          .toList();

      setState(() {
        _allLocations = fallback;
        _filteredLocations = fallback;
        _isLoading = false;
      });
    }
  }

  void _filterLocations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLocations = _allLocations;
      } else {
        _filteredLocations = _allLocations
            .where(
              (loc) =>
                  loc.displayName.toLowerCase().contains(query.toLowerCase()) ||
                  loc.value.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  String _formatLocationName(String name) {
    String formatted = name.trim();

    formatted = formatted.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    formatted = formatted.replaceAllMapped(
      RegExp(r'([a-zA-Z])(\d)'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    formatted = formatted.replaceAllMapped(
      RegExp(r'(\d)([a-zA-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    formatted = formatted
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');

    formatted = formatted.replaceAll(RegExp(r'\s+'), ' ');

    return formatted;
  }

  bool _isHardcodedLocation(String value) {
    return _hardcodedLocations.contains(value.toLowerCase());
  }

  Future<void> _addNewLocation(String name) async {
    if (name.trim().isEmpty) return;

    final displayName = _formatLocationName(name);
    final value = displayName.toLowerCase().replaceAll(' ', '_');

    final random = Random();
    final colors = [
      0xFFF44336,
      0xFFE91E63,
      0xFF9C27B0,
      0xFF673AB7,
      0xFF3F51B5,
      0xFF2196F3,
      0xFF03A9F4,
      0xFF00BCD4,
      0xFF009688,
      0xFF4CAF50,
      0xFF8BC34A,
      0xFFCDDC39,
      0xFFFFEB3B,
      0xFFFFC107,
      0xFFFF9800,
      0xFFFF5722,
    ];
    final colorValue = colors[random.nextInt(colors.length)];

    try {
      final locationService = ref.read(locationServiceProvider);
      await locationService.addLocation(
        value: value,
        displayName: displayName,
        colorValue: colorValue,
        sortOrder: _allLocations.length + 1,
      );

      await _loadLocations();

      widget.onLocationSelected.call(value);

      _searchController.clear();
      _filterLocations('');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location "$displayName" added')),
        );
        widget.onLocationCreated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onLocationLongPress(LocationDisplayData location) async {
    if (!widget.showDeleteOption) return;
    if (_isHardcodedLocation(location.value)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${location.displayName} is a default location and cannot be deleted',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    await _countContactsWithLocation(location.value);

    setState(() {
      _locationToDelete = location.value;
    });
  }

  void _cancelDeleteMode() {
    setState(() {
      _locationToDelete = null;
    });
  }

  Future<void> _deleteLocationTag(
    String locationValue,
    String displayName,
  ) async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final locationService = ref.read(locationServiceProvider);
      final entity = await locationService.getLocationByValue(locationValue);

      if (entity != null) {
        await locationService.deactivateLocation(entity.id);
        await _loadLocations();

        if (widget.selectedLocation == locationValue) {
          widget.onLocationSelected.call(null);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location "$displayName" removed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _locationToDelete = null;
        });
      }
    }
  }

  Future<int> _countContactsWithLocation(String locationValue) async {
    try {
      final database = ref.read(databaseProvider);
      final contacts = await database.getAllContacts();
      int count = 0;
      for (final contact in contacts) {
        if (contact.metadata != null && contact.metadata!.isNotEmpty) {
          try {
            final tags = _extractTagsFromMetadata(contact.metadata);
            if (tags.contains(locationValue)) {
              count++;
            }
          } catch (_) {}
        }
      }
      return count;
    } catch (e) {
      return 0;
    }
  }

  List<String> _extractTagsFromMetadata(String? metadata) {
    if (metadata == null || metadata.isEmpty) return [];
    try {
      if (metadata.contains('tags')) {
        final start = metadata.indexOf('[');
        final end = metadata.indexOf(']');
        if (start != -1 && end != -1 && end > start) {
          final tagsStr = metadata.substring(start + 1, end);
          if (tagsStr.isNotEmpty) {
            return tagsStr
                .split(',')
                .map((t) => t.trim().replaceAll('"', ''))
                .toList();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing metadata: $e');
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = widget.compact ? 200.0 : 340.0;

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimens.paddingL),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search location...',
            prefixIcon: const Icon(
              Icons.search,
              size: 20,
              color: AppColors.neutral400,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      size: 18,
                      color: AppColors.neutral400,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _filterLocations('');
                    },
                  )
                : null,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            fillColor: Theme.of(context).inputDecorationTheme.fillColor,
          ),
          onChanged: _filterLocations,
          style: AppTypography.bodyMedium,
        ),

        SizedBox(
          height: widget.compact ? AppDimens.paddingS : AppDimens.paddingM,
        ),

        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: AppDimens.paddingS,
              runSpacing: AppDimens.paddingS,
              children: [
                FilterChip(
                  label: const Text('None', style: AppTypography.labelMedium),
                  avatar: const Icon(
                    Icons.clear,
                    size: 18,
                    color: AppColors.neutral500,
                  ),
                  selected: widget.selectedLocation == null,
                  onSelected: (selected) {
                    if (selected) {
                      widget.onLocationSelected.call(null);
                    }
                  },
                  backgroundColor: Theme.of(context).chipTheme.backgroundColor,
                  selectedColor: Theme.of(context).chipTheme.selectedColor,
                  side: BorderSide(
                    color: widget.selectedLocation == null
                        ? AppColors.neutral400
                        : AppColors.neutral100,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusL),
                  ),
                ),

                ..._filteredLocations.map((location) {
                  final isSelected = widget.selectedLocation == location.value;
                  return _buildLocationChip(location, isSelected);
                }),

                if (_searchController.text.isNotEmpty &&
                    !_filteredLocations.any(
                      (loc) =>
                          loc.displayName.toLowerCase() ==
                              _searchController.text.toLowerCase() ||
                          loc.value.toLowerCase() ==
                              _searchController.text.toLowerCase().replaceAll(
                                ' ',
                                '_',
                              ),
                    ))
                  ActionChip(
                    avatar: const Icon(
                      Icons.add,
                      size: 18,
                      color: AppColors.cyan600,
                    ),
                    label: Text(
                      'Add "${_formatLocationName(_searchController.text)}"',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.cyan600,
                      ),
                    ),
                    onPressed: () => _addNewLocation(_searchController.text),
                    backgroundColor: AppColors.cyan50,
                    side: const BorderSide(color: AppColors.cyan200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusL),
                    ),
                  ),

                if (widget.showDeleteOption &&
                    _locationToDelete == null &&
                    _searchController.text.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Long press to delete',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neutral400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        if (_searchController.text.isNotEmpty &&
            _filteredLocations.length < _allLocations.length)
          Padding(
            padding: const EdgeInsets.only(top: AppDimens.paddingM),
            child: Text(
              'Showing ${_filteredLocations.length} of ${_allLocations.length} locations',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.neutral400,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationChip(LocationDisplayData location, bool isSelected) {
    final isInDeleteMode = _locationToDelete == location.value;
    final canDelete = !_isHardcodedLocation(location.value);

    if (isInDeleteMode) {
      return GestureDetector(
        onTap: _cancelDeleteMode,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppDimens.radiusL),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isDeleting)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                  onPressed: () async {
                    _cancelDeleteMode();
                    await _deleteLocationTag(
                      location.value,
                      location.displayName,
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 4),
              Text(
                location.displayName,
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: () => _onLocationLongPress(location),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!canDelete && widget.showDeleteOption)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.lock, size: 14, color: AppColors.neutral400),
              ),
            Text(
              location.displayName,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected
                    ? location.color
                    : Theme.of(context).chipTheme.labelStyle?.color,
              ),
            ),
          ],
        ),
        avatar: Icon(
          location.icon,
          size: 18,
          color: isSelected ? location.color : AppColors.neutral400,
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (_locationToDelete != null) {
            _cancelDeleteMode();
            return;
          }
          widget.onLocationSelected.call(selected ? location.value : null);
        },
        selectedColor: location.color.withValues(alpha: 0.15),
        checkmarkColor: location.color,
        backgroundColor: Theme.of(context).chipTheme.backgroundColor,
        side: BorderSide(
          color: isSelected
              ? location.color.withValues(alpha: 0.3)
              : AppColors.neutral200,
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
        ),
        showCheckmark: false,
      ),
    );
  }
}
