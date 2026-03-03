import 'dart:math';

import 'package:church_attendance_app/core/constants/app_colors.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/constants/app_typography.dart';
import 'package:church_attendance_app/core/enums/contact_tag.dart';
import 'package:church_attendance_app/core/services/location_service.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:church_attendance_app/features/contacts/presentation/providers/contact_provider.dart';
import 'package:church_attendance_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


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

class _ContactEditScreenState extends ConsumerState<ContactEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _locationSearchController;
  
  bool _isMember = false;
  String? _selectedLocation;
  final Set<String> _selectedRoles = {};
  bool _isSaving = false;
  
  // Location state
  bool _isLoadingLocations = true;
  List<LocationDisplayData> _allLocations = [];
  List<LocationDisplayData> _filteredLocations = [];

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
  }

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

  Future<void> _addNewLocation(String name) async {
    if (name.trim().isEmpty) return;
    
    final value = name.trim().toLowerCase().replaceAll(' ', '_');
    
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
        displayName: name.trim(),
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
          SnackBar(content: Text('Location "$name" added')),
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
    super.dispose();
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
                    hint: 'Enter phone number',
                    prefixIcon: Icons.phone_outlined,
                    isRequired: true,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      if (value.trim().length < 10) {
                        return 'Enter a valid phone number';
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
              icon: Icons.card_membership_outlined,
              child: _buildStyledSwitch(
                title: 'Member',
                subtitle: 'Mark as church member',
                value: _isMember,
                onChanged: (value) => setState(() => _isMember = value),
              ),
            ),
            const SizedBox(height: AppDimens.paddingM),

            // Location Section - Dynamic from database
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
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
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
            const SizedBox(height: AppDimens.paddingM),

            // Role Section
            _buildSectionCard(
              context: context,
              title: 'Role',
              icon: Icons.work_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select roles/ministry positions',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  
                  Wrap(
                    spacing: AppDimens.paddingS,
                    runSpacing: AppDimens.paddingS,
                    children: ContactTag.roleTags.map((role) {
                      final isSelected = _selectedRoles.contains(role.value);
                      return FilterChip(
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
                      );
                    }).toList(),
                  ),
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
        
        // Location chips (scrollable)
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 150),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: AppDimens.paddingS,
              runSpacing: AppDimens.paddingS,
              children: [
                // "No location" option
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
                
                // Location chips
                ..._filteredLocations.map((location) {
                  final isSelected = _selectedLocation == location.value;
                  return FilterChip(
                    label: Text(
                      location.displayName,
                      style: AppTypography.labelMedium.copyWith(
                        color: isSelected ? location.color : Theme.of(context).chipTheme.labelStyle?.color,
                      ),
                    ),
                    avatar: Icon(
                      location.icon,
                      size: 18,
                      color: isSelected ? location.color : AppColors.neutral400,
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
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
                  );
                }),
                
                // "Add new" chip when searching
                if (_locationSearchController.text.isNotEmpty &&
                    !_filteredLocations.any((loc) => 
                        loc.displayName.toLowerCase() == 
                        _locationSearchController.text.toLowerCase()))
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18, color: AppColors.cyan600),
                    label: Text(
                      'Add "${_locationSearchController.text}"',
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
