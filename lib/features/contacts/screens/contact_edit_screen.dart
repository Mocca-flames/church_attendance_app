import 'dart:math';

import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/enums/contact_tag.dart';
import 'package:church_attendance_app/core/services/location_service.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:church_attendance_app/features/contacts/presentation/providers/contact_provider.dart';
import 'package:church_attendance_app/main.dart';
import 'package:flutter/material.dart';
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
        title: const Text('Add New Location'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Location Name',
            hintText: 'e.g., Pretoria',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
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
        // Add role tags if editing
        if (isEditing && _selectedRoles.isNotEmpty) {
          await notifier.addTags(widget.contact!.id, _selectedRoles.toList());
        }
        
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Contact' : 'New Contact'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          children: [
            // Basic Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    
                    // Phone Field
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone *',
                        hintText: 'Enter phone number',
                        prefixIcon: Icon(Icons.phone),
                      ).applyDefaults(Theme.of(context).inputDecorationTheme),
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
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Enter name (optional)',
                        prefixIcon: Icon(Icons.person),
                      ).applyDefaults(Theme.of(context).inputDecorationTheme),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimens.paddingM),

            // Membership Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Membership',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    
                    SwitchListTile(
                      title: const Text('Member'),
                      subtitle: const Text('Mark as church member'),
                      value: _isMember,
                      onChanged: (value) {
                        setState(() => _isMember = value);
                      },
                      activeTrackColor: Colors.green.withValues(alpha:0.5),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimens.paddingM),

            // Location Card - Dynamic from database
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Location',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _showAddLocationDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add New'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.paddingS),
                    Text(
                      'Select or add the area this contact belongs to',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    
                    if (_isLoadingLocations)
                      const Center(child: CircularProgressIndicator())
                    else
                      _buildLocationSelector(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimens.paddingM),

            // Role Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Role',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingS),
                    Text(
                      'Select roles/ministry positions',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ContactTag.roleTags.map((role) {
                        final isSelected = _selectedRoles.contains(role.value);
                        return FilterChip(
                          label: Text(role.displayName),
                          avatar: Icon(
                            role.icon,
                            size: 18,
                            color: isSelected ? role.color : Colors.grey,
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
                          selectedColor: role.color.withValues(alpha:0.2),
                          checkmarkColor: role.color,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimens.paddingXL),
          ],
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
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
          onChanged: _filterLocations,
        ),
        
        const SizedBox(height: 8),
        
        // Location chips (scrollable)
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 150),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // "No location" option
                FilterChip(
                  label: const Text('None'),
                  avatar: const Icon(Icons.clear, size: 18),
                  selected: _selectedLocation == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedLocation = null);
                    }
                  },
                ),
                
                // Location chips
                ..._filteredLocations.map((location) {
                  final isSelected = _selectedLocation == location.value;
                  return FilterChip(
                    label: Text(location.displayName),
                    avatar: Icon(
                      location.icon,
                      size: 18,
                      color: isSelected ? location.color : Colors.grey,
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedLocation = selected ? location.value : null;
                      });
                    },
                    selectedColor: location.color.withValues(alpha: 0.2),
                    checkmarkColor: location.color,
                  );
                }),
                
                // "Add new" chip when searching
                if (_locationSearchController.text.isNotEmpty &&
                    !_filteredLocations.any((loc) => 
                        loc.displayName.toLowerCase() == 
                        _locationSearchController.text.toLowerCase()))
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text('Add "${_locationSearchController.text}"'),
                    onPressed: () => _addNewLocation(_locationSearchController.text),
                  ),
              ],
            ),
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
    );
  }
}
