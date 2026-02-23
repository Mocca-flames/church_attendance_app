import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/enums/service_type.dart';
import 'package:church_attendance_app/features/attendance/presentation/providers/contact_search_provider.dart';
import 'package:church_attendance_app/features/attendance/presentation/screens/attendance_history_screen.dart';
import 'package:church_attendance_app/features/attendance/presentation/screens/qr_scanner_screen.dart';
import 'package:church_attendance_app/features/attendance/presentation/widgets/contact_result_card.dart';
import 'package:church_attendance_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:church_attendance_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/quick_contact_dialog.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  ServiceType get _currentServiceType => ServiceType.getServiceTypeByDay();

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
    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);
    final nextDay = dateOnly.add(const Duration(days: 1));

    final attendances =
        await database.getAttendancesByDateRange(dateOnly, nextDay);

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
          builder: (_) => QRScannerScreen(serviceType: _currentServiceType)),
    );
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
    );
  }

  void _handleNewContact(String scannedPhone) async {
    final currentUser = ref.read(currentUserProvider);
    final userId = currentUser?.id ?? 1;

    final result = await showQuickContactSheet(
      context,
      phone: scannedPhone,
      serviceType: _currentServiceType,
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

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(contactSearchProvider);
    final currentServiceType = _currentServiceType;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.attendance),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _navigateToHistory,
            tooltip: 'Attendance History',
          ),
        ],
      ),
      body: Column(
        children: [
          // Service Type Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recording for: ${_getServiceTypeDisplayName(currentServiceType)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'attendance_fab', // Unique tag to prevent Hero conflict
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
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
        itemBuilder: (_, __) => const ContactResultCardSkeleton(),
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
          recordedBy: userId, // Use the authenticated user's ID
          onAttendanceMarked: _loadMarkedContacts,
        );
      },
    );
  }
}