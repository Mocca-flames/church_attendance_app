import 'package:church_attendance_app/core/enums/service_type.dart';
import 'package:church_attendance_app/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<CreateContactAttendanceResult?> showQuickContactSheet(
  BuildContext context, {
  required String phone,
  required ServiceType serviceType,
  required int recordedBy,
}) async {
  return showModalBottomSheet<CreateContactAttendanceResult?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true, // Adds top padding for notches
    showDragHandle: true, // Modern native drag handle
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _QuickContactSheet(
      phone: phone,
      serviceType: serviceType,
      recordedBy: recordedBy,
    ),
  );
}

class _QuickContactSheet extends ConsumerStatefulWidget {
  final String phone;
  final ServiceType serviceType;
  final int recordedBy;

  const _QuickContactSheet({
    required this.phone,
    required this.serviceType,
    required this.recordedBy,
  });

  @override
  ConsumerState<_QuickContactSheet> createState() => _QuickContactSheetState();
}

class _QuickContactSheetState extends ConsumerState<_QuickContactSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  
  bool _isMember = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController(text: widget.phone);
    _locationController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final result = await ref.read(attendanceProvider.notifier)
          .createContactAndRecordAttendance(
        phone: _phoneController.text.trim(),
        name: _nameController.text.trim(),
        serviceType: widget.serviceType,
        serviceDate: DateTime.now(),
        recordedBy: widget.recordedBy,
        isMember: _isMember,
        location: _locationController.text.trim().isEmpty 
            ? null 
            : _locationController.text.trim(),
      );

      if (mounted) {
        if (result.alreadyMarked) {
          // Contact saved but already marked for today
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact saved! Already marked for this service today.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pop(result);
        } else if (result.error != null) {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result.error}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red.shade600,
            ),
          );
        } else {
          // Success - contact saved and attendance recorded
          Navigator.of(context).pop(result);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Contact',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Record attendance details',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Phone Field
              _ModernTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) => (value?.length ?? 0) < 2 
                    ? 'Invalid phone number' 
                    : null,
              ),
              const SizedBox(height: 16),

              // Name Field
              _ModernTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                validator: (value) => (value?.isEmpty ?? true) 
                    ? 'Name is required' 
                    : null,
              ),
              const SizedBox(height: 16),

              // Location Field
              _ModernTextField(
                controller: _locationController,
                label: 'Location (Optional)',
                icon: Icons.location_on_outlined,
                textCapitalization: TextCapitalization.words,
                isLast: true,
              ),
              const SizedBox(height: 20),

              // Modern Checkbox (Selectable Card)
              _ModernMembershipSelector(
                isMember: _isMember,
                onChanged: (val) => setState(() => _isMember = val),
              ),
              
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save & Mark Attendance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Reusable Modern Components ---

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final bool isLast;

  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor, 
            width: 1.5
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error, 
            width: 1.5
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20, 
          vertical: 18
        ),
      ),
      validator: validator,
    );
  }
}

class _ModernMembershipSelector extends StatelessWidget {
  final bool isMember;
  final ValueChanged<bool> onChanged;

  const _ModernMembershipSelector({
    required this.isMember,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.primaryColor;

    return GestureDetector(
      onTap: () => onChanged(!isMember),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMember 
              ? activeColor.withOpacity(0.08) 
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMember 
                ? activeColor 
                : Colors.grey.shade300,
            width: isMember ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isMember 
                    ? activeColor.withOpacity(0.15) 
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.card_membership_rounded,
                color: isMember ? activeColor : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Church Member',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isMember ? activeColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Is this person a registered member?',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                color: isMember ? activeColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isMember ? activeColor : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isMember
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}