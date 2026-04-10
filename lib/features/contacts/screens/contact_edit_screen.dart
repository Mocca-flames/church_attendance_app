import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/constants/app_colors.dart';
import 'package:church_attendance_app/core/constants/app_typography.dart';
import 'package:church_attendance_app/core/enums/contact_tag.dart';
import 'package:church_attendance_app/core/services/haptic_service.dart';
import 'package:church_attendance_app/core/services/location_service.dart';
import 'package:church_attendance_app/core/sync/sync_manager_provider.dart';
import 'package:church_attendance_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:church_attendance_app/features/contacts/presentation/providers/contact_provider.dart';

import 'package:church_attendance_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


/// Hardcoded location tags that cannot be deleted
const Set<String> _hardcodedLocations = {
  'kanana',
  'majaneng',
  'mashemong',
  'soshanguve',
  'kekana',
};


/// Contact Edit Screen for creating or editing contacts.
///
/// Features:
/// - Create new contact or edit existing
/// - Edit name and phone
/// - Toggle member status
/// - Select role tags
/// - Select location tag (dynamic from database)
/// - Add new locations on-the-fly
class ContactEditScreen extends ConsumerStatefulWidget {
  final Contact? contact;

  const ContactEditScreen({
    super.key,
    this.contact,
  });

  @override
  ConsumerState<ContactEditScreen> createState() => _ContactEditScreenState();
}

/// Text input formatter that formats SA phone numbers as user types
/// Converts: 0712345678 → 071 234 5678
class _SouthAfricanPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Get digits only
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    
    // Limit to 10 digits
    final limitedDigits = digits.length > 10 ? digits.substring(0, 10) : digits;
    
    // Format as 071 234 5678
    String formatted = '';
    for (int i = 0; i < limitedDigits.length; i++) {
      if (i == 3 || i == 6) {
        formatted += ' ';
      }
      formatted += limitedDigits[i];
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}



class _ContactEditScreenState extends ConsumerState<ContactEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _locationSearchController;
  Timer? _phoneSearchDebounce;
  
  bool _isMember = false;
  String? _selectedLocation;
  final Set<String> _selectedRoles = {};
  bool _isSaving = false;
  
  // Location state
  bool _isLoadingLocations = true;
  List<LocationDisplayData> _allLocations = [];
  List<LocationDisplayData> _filteredLocations = [];

  // Delete mode state for location chips
  String? _locationToDelete;
  bool _isDeleting = false;
  int _contactsWithLocation = 0;

  // Phone duplicate detection - Hash Maps for O(1) lookup
  Map<String, Contact> _phoneToContactMap = {}; // Exact match: +27XXXXXXXXX -> Contact
  Map<String, List<Contact>> _phoneSuffix7Map = {}; // Partial match: last 7 digits -> [Contacts]
  Contact? _exactDuplicate;
  List<Contact> _similarContacts = [];

  bool get isEditing => widget.contact != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    _phoneController = TextEditingController(text: widget.contact?.phone ?? '');
    _locationSearchController = TextEditingController();
    
    // Initialize from existing contact
    if (widget.contact != null) {
      _isMember = widget.contact!.isMember;
      _selectedLocation = widget.contact!.location;
      _selectedRoles.addAll(widget.contact!.roleTags);
    }
    
    _loadLocations();
    _preloadPhoneMap();
  }

  /// Preload phone-to-contact Hash Maps for O(1) lookup
  /// - _phoneToContactMap: exact phone match (+27XXXXXXXXX -> Contact)
  /// - _phoneSuffix7Map: partial match (last 7 digits -> [Contacts])
  /// This is called once when screen loads for new contacts
  Future<void> _preloadPhoneMap() async {
    if (isEditing) return;
    
    try {
      final repository = ref.read(contactRepositoryProvider);
      final contacts = await repository.getAllContacts();
      
      // Build Hash Maps
      final exactMap = <String, Contact>{};
      final suffix7Map = <String, List<Contact>>{};
      
      for (final contact in contacts) {
        // Get normalized phone (e.g., +27821234567)
        final normalized = PhoneUtils.normalizeSouthAfricanPhone(contact.phone);
        if (normalized != null) {
          // Add to exact match map
          exactMap[normalized] = contact;
          
          // Add to suffix 7 map for partial matching
          final suffix7 = normalized.substring(normalized.length - 7);
          if (!suffix7Map.containsKey(suffix7)) {
            suffix7Map[suffix7] = [];
          }
          suffix7Map[suffix7]!.add(contact);
        }
      }
      
      if (mounted) {
        setState(() {
          _phoneToContactMap = exactMap;
          _phoneSuffix7Map = suffix7Map;
        });
      }
    } catch (e) {
      // Silent fail - fallback to on-demand loading
    }
  }


  Future<void> _loadLocations() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final locations = await locationService.getAllLocationsAsDisplayData();
      
      // Filter locations against server data - only show locations that exist on server
      // This is the second layer of protection in case sync didn't catch deleted locations
      final serverLocations = await _getServerLocations();
      
      List<LocationDisplayData> filteredLocations;
      if (serverLocations != null) {
        // Filter to only show locations that exist on server
        filteredLocations = locations.where((loc) {
          // Keep hardcoded locations always
          if (_hardcodedLocations.contains(loc.value.toLowerCase())) {
            return true;
          }
          // Keep if exists on server
          return serverLocations.contains(loc.value);
        }).toList();
      } else {
        // Fallback: use all local active locations if we can't reach server
        filteredLocations = locations;
      }
      
      setState(() {
        _allLocations = filteredLocations;
        _filteredLocations = filteredLocations;
        _isLoadingLocations = false;
      });
    } catch (e) {
      // Fallback to enum-based locations
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

  /// Get active location values from server via dashboardStatistics
  /// Returns null if offline or error
  Future<Set<String>?> _getServerLocations() async {
    try {
      final isOnline = ref.read(isOnlineProvider);
      if (!isOnline) return null;
      
      final dioClient = ref.read(dioClientProvider);
      final response = await dioClient.getDashboardStatistics();
      
      if (response.statusCode == 200 && response.data != null) {
        final locationsJson = response.data['locations'] as Map<String, dynamic>? ?? {};
        return locationsJson.keys.toSet();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

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

  /// Formats location name for display (auto-capitalize, proper spacing)
  /// Example: "unit 7" → "Unit 7", "unit7" → "Unit 7", "unit7hall" → "Unit 7 Hall"
  String _formatLocationName(String name) {
    // Trim and normalize spacing
    String formatted = name.trim();
    
    // Add space before capital letters that follow lowercase (camelCase to Title Case)
    // e.g., "Unit7" → "Unit 7", "Unit7Hall" → "Unit 7 Hall"
    formatted = formatted.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    
    // Add space before numbers that follow letters
    // e.g., "Unit7" → "Unit 7"
    formatted = formatted.replaceAllMapped(
      RegExp(r'([a-zA-Z])(\d)'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    
    // Add space after numbers that follow letters
    // e.g., "7Unit" → "7 Unit"
    formatted = formatted.replaceAllMapped(
      RegExp(r'(\d)([a-zA-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    
    // Convert to title case (capitalize first letter of each word)
    formatted = formatted.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
    
    // Clean up multiple spaces
    formatted = formatted.replaceAll(RegExp(r'\s+'), ' ');
    
    return formatted;
  }

  Future<void> _addNewLocation(String name) async {
    if (name.trim().isEmpty) return;
    
    // Auto-format the display name
    final displayName = _formatLocationName(name);
    
    // Create value for database (lowercase with underscores)
    final value = displayName.toLowerCase().replaceAll(' ', '_');
    
    // Generate a random color
    final random = Random();
    final colors = [
      0xFFF44336, 0xFFE91E63, 0xFF9C27B0, 0xFF673AB7,
      0xFF3F51B5, 0xFF2196F3, 0xFF03A9F4, 0xFF00BCD4,
      0xFF009688, 0xFF4CAF50, 0xFF8BC34A, 0xFFCDDC39,
      0xFFFFEB3B, 0xFFFFC107, 0xFFFF9800, 0xFFFF5722,
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
      
      // Reload locations
      await _loadLocations();
      
      // Select the new location
      setState(() {
        _selectedLocation = value;
        _locationSearchController.clear();
        _filteredLocations = _allLocations;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location "$displayName" added')),
        );
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

  /// Check if a location is hardcoded (cannot be deleted)
  bool _isHardcodedLocation(String value) {
    return _hardcodedLocations.contains(value.toLowerCase());
  }

  /// Count contacts with a specific location tag
  Future<int> _countContactsWithLocation(String locationValue) async {
    try {
      final database = ref.read(databaseProvider);
      final contacts = await database.getAllContacts();
      int count = 0;
      for (final contact in contacts) {
        // Extract tags from metadata JSON
        final tags = _extractTagsFromMetadata(contact.metadata);
        if (tags.contains(locationValue)) {
          count++;
        }
      }
      return count;
    } catch (e) {
      return 0;
    }
  }

  /// Extract tags from metadata JSON string
  List<String> _extractTagsFromMetadata(String? metadata) {
    if (metadata == null || metadata.isEmpty) return [];
    try {
      final Map<String, dynamic> meta = jsonDecode(metadata);
      if (meta.containsKey('tags') && meta['tags'] is List) {
        return (meta['tags'] as List).map((e) => e.toString()).toList();
      }
    } catch (e) {
      // Invalid JSON
    }
    return [];
  }

  /// Show delete confirmation dialog
  Future<bool?> _showDeleteConfirmation(String locationName, int affectedCount) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Location'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$locationName"?\n\n'
          'This will remove this location from $affectedCount contact${affectedCount == 1 ? '' : 's'}.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Handle long-press to initiate delete mode
  Future<void> _onLocationLongPress(LocationDisplayData location) async {
    // Don't allow deleting hardcoded locations
    if (_isHardcodedLocation(location.value)) {
      HapticService.medium();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${location.displayName} is a default location and cannot be deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Provide haptic feedback
    HapticService.medium();

    // Count contacts with this location
    final count = await _countContactsWithLocation(location.value);

    setState(() {
      _locationToDelete = location.value;
      _contactsWithLocation = count;
    });
  }

  /// Cancel delete mode
  void _cancelDeleteMode() {
    setState(() {
      _locationToDelete = null;
      _contactsWithLocation = 0;
    });
  }

  /// Delete location from all contacts
  Future<void> _deleteLocationTag(String locationValue, String displayName) async {
    setState(() {
      _isDeleting = true;
    });

    try {
      // Get the repository and call delete
      final repository = ref.read(contactRepositoryProvider);
      final result = await repository.deleteLocationTag(locationValue);

      if (mounted) {
        final success = result['success'] as bool? ?? false;
        final message = result['message'] as String? ?? 'Location deleted';
        final deletedCount = result['contacts_updated'] as int? ?? 0;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'Successfully removed "$displayName" from $deletedCount contact${deletedCount == 1 ? '' : 's'}'
                : message),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          // Refresh the locations list
          await _loadLocations();
          
          // Clear selection if this was the selected location
          if (_selectedLocation == locationValue) {
            setState(() {
              _selectedLocation = null;
            });
          }
          
          // Refresh contacts list to update UI - this ensures deleted location tags
          // are removed from all contact cards across the app
          ref.read(contactNotifierProvider.notifier).refreshContacts();
          ref.invalidate(contactListProvider);
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

  Future<void> _showAddLocationDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Location',
          style: AppTypography.h4.copyWith(
            color: AppColors.neutral800,
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Location Name',
            hintText: 'e.g., Thambo',
            prefixIcon: Icon(Icons.location_on_outlined),
          ).applyDefaults(Theme.of(context).inputDecorationTheme),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.neutral500,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.cyan500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusL),
              ),
            ),
            child: const Text(
              'Add',
              style: AppTypography.labelLarge,
            ),
          ),
        ],
      ),
    );
    
    if (result != null && result.trim().isNotEmpty) {
      await _addNewLocation(result.trim());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationSearchController.dispose();
    _phoneSearchDebounce?.cancel();
    super.dispose();
  }

  /// Check for phone duplicates using Hash Map O(1) lookup
  /// Called on each keystroke with instant feedback
  void _onPhoneChanged(String value) {
    // Remove spaces to get raw digits
    final digitsOnly = value.replaceAll(' ', '');
    
    // Need at least 10 digits for a valid SA phone number
    if (digitsOnly.length < 10) {
      // Not enough digits - clear duplicates
      if (_exactDuplicate != null || _similarContacts.isNotEmpty) {
        setState(() {
          _exactDuplicate = null;
          _similarContacts = [];
        });
      }
      return;
    }
    
    if (isEditing || _phoneToContactMap.isEmpty) {
      // Skip search if editing or no data loaded
      return;
    }
    
    // Normalize input to +27XXXXXXXXX format for exact match
    final normalized = PhoneUtils.normalizeSouthAfricanPhone(digitsOnly);
    
    if (normalized != null) {
      // O(1) Hash Map lookup for exact match
      final exactMatch = _phoneToContactMap[normalized];
      
      if (exactMatch != null) {
        // Exact match found - show Alert Dialog
        setState(() => _exactDuplicate = exactMatch);
      } else {
        // No exact match - clear and check for partial match
        if (_exactDuplicate != null) {
          setState(() => _exactDuplicate = null);
        }
        _checkPartialMatch(normalized);
      }
    }
  }

  /// Check for partial matches using Hash Map (last 7 digits)
  /// Uses pre-built _phoneSuffix7Map for O(1) lookup
  void _checkPartialMatch(String normalizedPhone) {
    if (normalizedPhone.length < 7) {
      setState(() => _similarContacts = []);
      return;
    }
    
    // Get last 7 digits - O(1) Hash Map lookup
    final suffix7 = normalizedPhone.substring(normalizedPhone.length - 7);
    final matches = _phoneSuffix7Map[suffix7] ?? [];
    
    if (mounted) {
      setState(() => _similarContacts = matches);
    }
  }

  /// Show Alert Dialog when exact duplicate found
  /// Allows user to navigate to Edit Contact or continue creating new
  Future<void> _showDuplicateAlertDialog(Contact duplicate) async {
    if (!mounted) return;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.contact_phone, color: AppColors.cyan500, size: 32),
        title: const Text('Contact Already Exists'),
        content: Text(
          'Name: ${duplicate.name ?? 'Unknown'}\n'
          'Phone: ${duplicate.phone}\n\n'
          'Would you like to edit this contact instead?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Create New',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.neutral500,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.cyan500,
              foregroundColor: Colors.white,
            ),
            child: const Text('Go to Contact'),
          ),
        ],
      ),
    );
    
    if (result == true && mounted) {
      // Navigate to edit screen with existing contact
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ContactEditScreen(contact: duplicate),
        ),
      );
    } else if (result == false && mounted) {
      // User chose "Create New" - clear phone field to prevent duplicates
      _phoneController.clear();
      setState(() {
        _exactDuplicate = null;
        _similarContacts = [];
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(contactNotifierProvider.notifier);
      
      // Build tags list
      final tags = <String>[];
      if (_isMember) tags.add('member');
      if (_selectedLocation != null) tags.add(_selectedLocation!);
      tags.addAll(_selectedRoles);

      Contact? result;
      
      if (isEditing) {
        // Update existing contact
        final updatedContact = widget.contact!.copyWith(
          name: _nameController.text.trim().isEmpty 
              ? null 
              : _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          metadata: tags.isNotEmpty 
              ? '{"tags":${tags.map((t) => '"$t"').toList()}}' 
              : null,
        );
        result = await notifier.updateContact(updatedContact);
      } else {
        // Create new contact
        result = await notifier.createContact(
          phone: _phoneController.text.trim(),
          name: _nameController.text.trim().isEmpty 
              ? null 
              : _nameController.text.trim(),
          isMember: _isMember,
          location: _selectedLocation,
        );
      }

      if (result != null && mounted) {
        // All tags (member, location, roles) are now synced via updateContact
        // No need for separate addTags call
        
        // Check mounted again after async gap before using context
        if (!mounted) return;
        
        // Refresh the contacts list to ensure UI updates
        // Use the notifier's refresh method which updates recentContacts
        ref.read(contactNotifierProvider.notifier).refreshContacts();
        // Also invalidate the async provider to ensure data is fresh
        ref.invalidate(contactListProvider);
        
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Contact updated' : 'Contact created'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Builds the save button for the AppBar with modern styling
  Widget _buildSaveButton(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(right: AppDimens.paddingS),
      child: _isSaving
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.cyan500,
              ),
            )
          : FilledButton.icon(
              onPressed: _handleSave,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Save'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.cyan500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingM,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusL),
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Show alert dialog when exact duplicate found
    if (_exactDuplicate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDuplicateAlertDialog(_exactDuplicate!);
        // Reset to prevent repeated showing
        setState(() => _exactDuplicate = null);
      });
    }
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Contact' : 'New Contact',
          style: AppTypography.h3.copyWith(
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          _buildSaveButton(colorScheme),
        ],
      ),
     // Spacer to push content below AppBar
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(
            top: AppDimens.paddingL + 56, // Account for AppBar
            left: AppDimens.paddingM,
            right: AppDimens.paddingM,
            bottom: AppDimens.paddingXL,
          ),
          children: [
            // Subtle phone duplicate preview popup
            // DEBUG: Log state before showing popup
            if (_similarContacts.isNotEmpty && !isEditing) _buildPhoneDuplicatePopup(),

            // Basic Info Section
             const SizedBox(height: AppDimens.paddingL),
            _buildSectionCard(
              context: context,
              title: 'Basic Information',
              icon: Icons.person_outline,
              child: Column(
                children: [
                  // Phone Field
                  _buildFormField(
                    controller: _phoneController,
                    label: 'Phone',
                    hint: '071 234 5678',
                    prefixIcon: Icons.phone_outlined,
                    isRequired: true,
                    keyboardType: TextInputType.phone,
                    readOnly: isEditing,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _SouthAfricanPhoneFormatter(),
                    ],
                    onChanged: isEditing ? null : _onPhoneChanged,
                    validator: (value) {
                      // Skip validation when editing - phone is read-only and may be in +27 format from server
                      if (isEditing) {
                        return null;
                      }
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      // Remove spaces for validation
                      final digitsOnly = value.replaceAll(' ', '');
                      // Must be exactly 10 digits (e.g., 0712345678)
                      if (digitsOnly.length != 10) {
                        return 'Enter 10 digits: 071 234 5678';
                      }
                      // Must start with valid SA mobile prefix (06-09)
                      final prefix = digitsOnly.substring(0, 2);
                      if (!['06', '07', '08', '09'].contains(prefix)) {
                        return 'Invalid SA number. Use 06x-09x xxx xxxx';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  
                  // Name Field
                  _buildFormField(
                    controller: _nameController,
                    label: 'Name',
                    hint: 'Enter name (optional)',
                    prefixIcon: Icons.person_outline,
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.paddingM),

            // Membership Section
            _buildSectionCard(
              context: context,
              title: 'Membership',
              icon: Icons.contact_phone_outlined,
              child: _buildStyledSwitch(
                title: 'Member',
                subtitle: 'Mark as church member',
                value: _isMember,
                onChanged: (value) => setState(() => _isMember = value),
              ),
            ),
            const SizedBox(height: AppDimens.paddingM),

            // Role Section (first - fewer items)
            _buildSectionCard(
              context: context,
              title: 'Role',
              icon: Icons.work_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select roles/ministry positions',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withValues(alpha: 1.0),
                  ),
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  
                  // Role chips (horizontal scrollable)
                  SizedBox(
                    height: 40,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ContactTag.roleTags.asMap().entries.map((entry) {
                          final role = entry.value;
                          final isSelected = _selectedRoles.contains(role.value);
                          return Padding(
                            padding: EdgeInsets.only(
                              right: entry.key < ContactTag.roleTags.length - 1 
                                  ? AppDimens.paddingS 
                                  : 0,
                            ),
                            child: FilterChip(
                              label: Text(
                                role.displayName,
                                style: AppTypography.labelMedium.copyWith(
                                  color: isSelected ? role.color : Theme.of(context).chipTheme.labelStyle?.color,
                                ),
                              ),
                              avatar: Icon(
                                role.icon,
                                size: 18,
                                color: isSelected ? role.color : AppColors.neutral400,
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedRoles.add(role.value);
                                  } else {
                                    _selectedRoles.remove(role.value);
                                  }
                                });
                              },
                              selectedColor: role.color.withValues(alpha: 0.15),
                              checkmarkColor: role.color,
                              backgroundColor: Theme.of(context).chipTheme.backgroundColor,
                              side: BorderSide(
                                color: isSelected 
                                    ? role.color.withValues(alpha: 0.3)
                                    : AppColors.neutral200,
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDimens.radiusL),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.paddingM),

            // Location Section - Dynamic from database (last - more items, needs more space)
            _buildSectionCard(
              context: context,
              title: 'Location',
              icon: Icons.location_on_outlined,
              trailing: TextButton.icon(
                onPressed: _showAddLocationDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add New'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.cyan600,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingS,
                    vertical: 4,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select or add the area this contact belongs to',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withValues(alpha: 1.0),
                  ),),
                  const SizedBox(height: AppDimens.paddingM),
                  
                  if (_isLoadingLocations)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppDimens.paddingL),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else
                    _buildLocationSelector(),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.paddingXL),
          ],
        ),
      ),
    );
  }

  /// Builds a section card with flat bordered design matching ContactCard
  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusXL),
        border: Border.all(
          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: AppDimens.paddingS),
                    Text(
                      title,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: AppDimens.paddingM),
            child,
          ],
        ),
      ),
    );
  }

  /// Builds a form text field with consistent styling
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    bool isRequired = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool readOnly = false,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon),
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
      keyboardType: keyboardType,
      validator: validator,
      textCapitalization: textCapitalization,
      readOnly: readOnly,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
    );
  }

  /// Build subtle phone duplicate preview popup
  /// Shows phone numbers with similar endings from local database
  Widget _buildPhoneDuplicatePopup() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: AppDimens.paddingS),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingS,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1), // Amber 50
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(
          color: const Color(0xFFFFE082).withValues(alpha: 0.5), // Amber 200
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: Colors.amber[800],
          ),
          const SizedBox(width: AppDimens.paddingS),
          Expanded(
            child: Text(
              'Similar: ${_similarContacts.map((c) => c.phone).join(', ')}',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.amber[900],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a styled switch with cyan accent matching the design system
  Widget _buildStyledSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        border: Border.all(
          color: value ? AppColors.cyan200 : AppColors.neutral200,
          width: 1,
        ),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.neutral800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.neutral500,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.cyan500,
        activeTrackColor: AppColors.cyan100,
        inactiveThumbColor: AppColors.neutral400,
        inactiveTrackColor: AppColors.neutral200,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
        ),
      ),
    );
  }

  /// Build location chip with delete support
  Widget _buildLocationChip(LocationDisplayData location, bool isSelected) {
    final isInDeleteMode = _locationToDelete == location.value;
    final canDelete = !_isHardcodedLocation(location.value);

    if (isInDeleteMode) {
      // Show delete overlay
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
                    final confirmed = await _showDeleteConfirmation(
                      location.displayName,
                      _contactsWithLocation,
                    );
                    if (confirmed == true && mounted) {
                      await _deleteLocationTag(location.value, location.displayName);
                    } else {
                      _cancelDeleteMode();
                    }
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
            if (!canDelete)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.lock, size: 14, color: AppColors.neutral400),
              ),
            Text(
              location.displayName,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? location.color : Theme.of(context).chipTheme.labelStyle?.color,
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
          // If in delete mode, cancel it
          if (_locationToDelete != null) {
            _cancelDeleteMode();
            return;
          }
          // Normal selection
          setState(() {
            _selectedLocation = selected ? location.value : null;
          });
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

  /// Build searchable location selector
  Widget _buildLocationSelector() {
    return Column(
      children: [
        // Search field
        TextField(
          controller: _locationSearchController,
          decoration: InputDecoration(
            hintText: 'Search location...',
            prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.neutral400),
            suffixIcon: _locationSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18, color: AppColors.neutral400),
                    onPressed: () {
                      _locationSearchController.clear();
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
        
        const SizedBox(height: AppDimens.paddingM),
        
        // Location chips (scrollable with 5 rows visible)
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 340),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: AppDimens.paddingS,
              runSpacing: AppDimens.paddingS,
              children: [
                // "No location" option (only when not in delete mode)
                if (_locationToDelete == null)
                  FilterChip(
                    label: const Text(
                      'None',
                      style: AppTypography.labelMedium,
                    ),
                    avatar: const Icon(Icons.clear, size: 18, color: AppColors.neutral500),
                    selected: _selectedLocation == null,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedLocation = null);
                      }
                    },
                    backgroundColor: Theme.of(context).chipTheme.backgroundColor,
                    selectedColor: Theme.of(context).chipTheme.selectedColor,
                    side: BorderSide(
                      color: _selectedLocation == null
                          ? AppColors.neutral400
                          : AppColors.neutral100,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusL),
                    ),
                  ),
                
                // Location chips with long-press delete
                ..._filteredLocations.map((location) {
                  final isSelected = _selectedLocation == location.value;
                  return _buildLocationChip(location, isSelected);
                }),
                
                // "Add new" chip when searching (only when not in delete mode)
                if (_locationToDelete == null &&
                    _locationSearchController.text.isNotEmpty &&
                    !_filteredLocations.any((loc) => 
                        loc.displayName.toLowerCase() == 
                        _locationSearchController.text.toLowerCase()))
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18, color: AppColors.cyan600),
                    label: Text(
                      'Add "${_formatLocationName(_locationSearchController.text)}"',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.cyan600,
                      ),
                    ),
                    onPressed: () => _addNewLocation(_locationSearchController.text),
                    backgroundColor: AppColors.cyan50,
                    side: const BorderSide(color: AppColors.cyan200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusL),
                    ),
                  ),

                // Hint to long-press (only when not in delete mode and not searching)
                if (_locationToDelete == null &&
                    _locationSearchController.text.isEmpty)
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
        
        // Show count if filtered
        if (_locationSearchController.text.isNotEmpty &&
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
}
