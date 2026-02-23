import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/enums/contact_tag.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:church_attendance_app/features/contacts/presentation/providers/contact_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contact Edit Screen for creating or editing contacts.
///
/// Features:
/// - Create new contact or edit existing
/// - Edit name and phone
/// - Toggle member status
/// - Select role tags
/// - Select location tag
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
  
  bool _isMember = false;
  String? _selectedLocation;
  final Set<String> _selectedRoles = {};
  bool _isSaving = false;

  bool get isEditing => widget.contact != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    _phoneController = TextEditingController(text: widget.contact?.phone ?? '');
    
    // Initialize from existing contact
    if (widget.contact != null) {
      _isMember = widget.contact!.isMember;
      _selectedLocation = widget.contact!.location;
      _selectedRoles.addAll(widget.contact!.roleTags);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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
        backgroundColor: AppColors.primary,
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
                        border: OutlineInputBorder(),
                      ),
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
                        border: OutlineInputBorder(),
                      ),
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

            // Location Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingS),
                    Text(
                      'Select the area this contact belongs to',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ContactTag.locationTags.map((location) {
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
                          selectedColor: location.color.withValues(alpha:0.2),
                          checkmarkColor: location.color,
                        );
                      }).toList(),
                    ),
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
}
