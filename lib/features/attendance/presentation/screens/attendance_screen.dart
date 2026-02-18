import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/enums/service_type.dart';
import 'package:church_attendance_app/features/attendance/presentation/providers/contact_search_provider.dart';
import 'package:church_attendance_app/features/attendance/presentation/screens/attendance_history_screen.dart';
import 'package:church_attendance_app/features/attendance/presentation/screens/qr_scanner_screen.dart';
import 'package:church_attendance_app/features/attendance/presentation/widgets/contact_result_card.dart';
import 'package:church_attendance_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/quick_contact_dialog.dart';

/// Attendance screen with search-first approach for marking attendance.
///
/// Features:
/// - Automatic service type based on day (Sunday/Tuesday/Special Event)
/// - PRIMARY: Search contacts by name or phone (local DB - instant)
/// - SECONDARY: QR code scanning via FAB
/// - MEMBER badge for members
/// - Already marked indicator (checkmark + grayed out)
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Set<int> _markedContactIds = {};

  /// Get the current service type based on today's day of the week.
  /// - Sunday → Sunday Service
  /// - Tuesday → Tuesday Service
  /// - Any other day → Special Event
  ServiceType get _currentServiceType => ServiceType.getServiceTypeByDay();

  @override
  void initState() {
    super.initState();
    _loadMarkedContacts();
    _searchFocusNode.addListener(() => setState(() {}));
  }

  /// Load contacts that are already marked for today's service.
  Future<void> _loadMarkedContacts() async {
    final database = ref.read(databaseProvider);
    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);
    final nextDay = dateOnly.add(const Duration(days: 1));

    final attendances =
        await database.getAttendancesByDateRange(dateOnly, nextDay);

    final markedIds = attendances
        .where((a) => a.serviceType == _currentServiceType.backendValue)
        .map((a) => a.contactId)
        .toSet();

    setState(() => _markedContactIds = markedIds);
  }

  void _navigateToScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRScannerScreen(
          serviceType: _currentServiceType,
        ),
      ),
    );
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AttendanceHistoryScreen(),
      ),
    );
  }

  // Example trigger inside a scanner callback or button
  void _handleNewContact(String scannedPhone) async {
    final result = await showQuickContactSheet(
      context,
      phone: scannedPhone,
      serviceType: ServiceType.sunday, // Pass your current service type
      recordedBy: 1, // Pass current user/admin ID
    );

    if (result != null) {
      // The dialog returned an Attendance object (Success!)
      print('Attendance recorded');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact saved and attendance recorded!')),
      );
    } else {
      // User cancelled the dialog
      print('User dismissed the dialog without saving.');
    }
  }

  void _onAttendanceMarked() {
    // Refresh the marked contacts list
    _loadMarkedContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(contactSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.attendance),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // History icon button
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _navigateToHistory,
            tooltip: 'Attendance History',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Field (PRIMARY)
          const SizedBox(height: AppDimens.paddingM),
          _buildSearchField(),

          // Results List
          Expanded(
            child: _buildResultsList(searchState),
          ),
        ],
      ),
      // QR Scanner FAB (SECONDARY)
      floatingActionButton: FloatingActionButton.extended(
        isExtended: !_searchFocusNode.hasFocus,
        onPressed: _navigateToScanner,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan QR'),
        backgroundColor: AppColors.attendanceColor,
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
        onTapOutside: (event) => _searchFocusNode.unfocus(),
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        onChanged: (query) {
          ref.read(contactSearchProvider.notifier).search(query);
        },
        textInputAction: TextInputAction.search,
      ),
    );
  }

  Widget _buildResultsList(dynamic searchState) {
    if (searchState.isLoading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => const ContactResultCardSkeleton(),
      );
    }

    if (searchState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: AppDimens.paddingM),
            Text(
              'Error loading contacts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              searchState.error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingM),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(contactSearchProvider.notifier)
                    .search(searchState.query);
              },
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
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppDimens.paddingM),
            Text(
              'Search for a contact',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              'Type a name or phone number to mark attendance',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (searchState.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppDimens.paddingM),
            Text(
              'No contacts found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
            ElevatedButton(onPressed: () {
                _handleNewContact(searchState.query);
              },child: const Text('New Contact')),
              
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: AppDimens.paddingS, bottom: 80),
      itemCount: searchState.results.length,
      itemBuilder: (context, index) {
        final contact = searchState.results[index];
        final isAlreadyMarked = _markedContactIds.contains(contact.id);

        return ContactResultCard(
          contact: contact,
          serviceType: _currentServiceType,
          isAlreadyMarked: isAlreadyMarked,
          onAttendanceMarked: _onAttendanceMarked,
        );
      },
    );
  }
}
