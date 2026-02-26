import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/enums/service_type.dart';
import 'package:church_attendance_app/features/attendance/presentation/providers/attendance_date_provider.dart';
import 'package:church_attendance_app/features/attendance/presentation/providers/contact_search_provider.dart';

import 'package:church_attendance_app/features/attendance/presentation/screens/qr_scanner_screen.dart';
import 'package:church_attendance_app/features/attendance/presentation/widgets/contact_result_card.dart';
import 'package:church_attendance_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:church_attendance_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/quick_contact_dialog.dart';


class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Get the attendance date state from provider
  AttendanceDateState get _dateState => ref.watch(attendanceDateProvider);
  
  // Convenience getters for the current service type and date
  ServiceType get _currentServiceType => _dateState.effectiveServiceType;
  DateTime get _currentServiceDate => _dateState.effectiveServiceDate;

  @override
  void initState() {
    super.initState();
    // Defer so ref is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMarkedContacts());
    _searchFocusNode.addListener(() => setState(() {}));
  }

  /// Queries the DB and writes results into [markedContactIdsProvider].
  /// Every widget watching that provider rebuilds automatically — no manual
  /// setState juggling needed.
  Future<void> _loadMarkedContacts() async {
    final database = ref.read(databaseProvider);
    
    // Use the effective service date for loading marked contacts
    final serviceDate = _currentServiceDate;
    final serviceDateOnly = DateTime(serviceDate.year, serviceDate.month, serviceDate.day);
    final serviceNextDay = serviceDateOnly.add(const Duration(days: 1));

    final attendances =
        await database.getAttendancesByDateRange(serviceDateOnly, serviceNextDay);

    if (!mounted) return;

    final markedIds = attendances
        .where((a) => a.serviceType == _currentServiceType.backendValue)
        .map((a) => a.contactId)
        .toSet();

    ref.read(markedContactIdsProvider.notifier).setAll(markedIds);
  }

  void _navigateToScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => QRScannerScreen(
            serviceType: _currentServiceType,
            serviceDate: _currentServiceDate,
          )),
    );
  }

  
  void _handleNewContact(String scannedPhone) async {
    final currentUser = ref.read(currentUserProvider);
    final userId = currentUser?.id ?? 1;

    final result = await showQuickContactSheet(
      context,
      phone: scannedPhone,
      serviceType: _currentServiceType,
      serviceDate: _currentServiceDate,
      recordedBy: userId,
    );

    if (!mounted) return;

    if (result != null) {
      if (result.alreadyMarked) {
        // Already marked - scanner already shows the snackbar, do nothing here
      } else if (result.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${result.error}'),
          backgroundColor: Colors.red,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Contact saved and attendance recorded!')));
      }
      _loadMarkedContacts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _getServiceTypeDisplayName(ServiceType serviceType) {
    return serviceType.displayName;
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Show date picker for selecting past date
  Future<void> _showDatePicker() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _dateState.selectedPastDate,
      firstDate: thirtyDaysAgo,
      lastDate: now,
      helpText: 'Select past date for attendance',
    );

    if (selectedDate != null) {
      ref.read(attendanceDateProvider.notifier).setSelectedPastDate(selectedDate);
      // Reload marked contacts for the new date
      _loadMarkedContacts();
    }
  }

  /// Show service type dropdown
  Future<void> _showServiceTypeSelector() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Select Service Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...ServiceType.values.map((type) => ListTile(
              leading: Icon(type.icon, color: type.color),
              title: Text(type.displayName),
              trailing: _dateState.selectedServiceType == type
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                ref.read(attendanceDateProvider.notifier).setSelectedServiceType(type);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(contactSearchProvider);

    return Scaffold(
      
      body: SafeArea(
        child: Column(
          children: [
            // Date Mode Toggle Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: _dateState.isPastDateMode
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          _dateState.isPastDateMode ? Icons.calendar_month : Icons.today,
                          size: 20,
                          color: _dateState.isPastDateMode
                              ? Theme.of(context).primaryColor
                              : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _dateState.isPastDateMode
                                    ? _formatDate(_dateState.selectedPastDate)
                                    : 'Today',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _dateState.isPastDateMode
                                      ? Theme.of(context).primaryColor
                                      : Colors.green[700],
                                ),
                              ),
                              if (_dateState.isPastDateMode)
                                Text(
                                  _getServiceTypeDisplayName(_dateState.selectedServiceType),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.7),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Toggle button
                  FilledButton.tonalIcon(
                    onPressed: () {
                      ref.read(attendanceDateProvider.notifier).togglePastDateMode();
                      // Reload marked contacts when mode changes
                      _loadMarkedContacts();
                    },
                    icon: Icon(_dateState.isPastDateMode ? Icons.today : Icons.calendar_month),
                    label: Text(_dateState.isPastDateMode ? 'Today' : 'Past Date'),
                  ),
                ],
              ),
            ),
            // Past Date Mode: Show date picker and service type selector
            if (_dateState.isPastDateMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                child: Row(
                  children: [
                    // Date picker button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showDatePicker,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(_formatDate(_dateState.selectedPastDate)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Service type selector
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showServiceTypeSelector,
                        icon: Icon(
                          _dateState.selectedServiceType.icon,
                          size: 18,
                          color: _dateState.selectedServiceType.color,
                        ),
                        label: Text(_dateState.selectedServiceType.displayName),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppDimens.paddingM),
            _buildSearchField(),
            Expanded(child: _buildResultsList(searchState)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'attendance_fab', // Unique tag to prevent Hero conflict
        isExtended: !_searchFocusNode.hasFocus,
        onPressed: _navigateToScanner,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan QR'),
        backgroundColor: AppColors.accentMint,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onTapOutside: (_) => _searchFocusNode.unfocus(),
        decoration: InputDecoration(
          hintText: 'Search by name or phone...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(contactSearchProvider.notifier).clear();
                  },
                )
              : null,
        ).applyDefaults(Theme.of(context).inputDecorationTheme),
        onChanged: (query) =>
            ref.read(contactSearchProvider.notifier).search(query),
        textInputAction: TextInputAction.search,
      ),
    );
  }

  Widget _buildResultsList(ContactSearchState searchState) {
    // Get the current authenticated user's ID for recording attendance
    final currentUser = ref.read(currentUserProvider);
    final userId = currentUser?.id ?? 1;
    
    if (searchState.isLoading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (_, _) => const ContactResultCardSkeleton(),
      );
    }

    if (searchState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: AppDimens.paddingM),
            Text('Error loading contacts',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppDimens.paddingS),
            Text(searchState.error!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppDimens.paddingM),
            ElevatedButton(
              onPressed: () => ref
                  .read(contactSearchProvider.notifier)
                  .search(searchState.query),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (searchState.query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: AppDimens.paddingM),
            Text('Search for a contact',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: AppDimens.paddingS),
            Text('Type a name or phone number to mark attendance',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    if (searchState.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: AppDimens.paddingM),
            Text('No contacts found',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: AppDimens.paddingS),
            Text('Try a different search term',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[500])),
            ElevatedButton(
              onPressed: () => _handleNewContact(searchState.query),
              child: const Text('New Contact'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: AppDimens.paddingS, bottom: 80),
      itemCount: searchState.results.length,
      itemBuilder: (context, index) {
        final contact = searchState.results[index];
        return ContactResultCard(
          key: ValueKey(contact.id), // stable key prevents widget reuse bugs
          contact: contact,
          serviceType: _currentServiceType,
          serviceDate: _currentServiceDate,
          recordedBy: userId, // Use the authenticated user's ID
          onAttendanceMarked: _loadMarkedContacts,
        );
      },
    );
  }
}