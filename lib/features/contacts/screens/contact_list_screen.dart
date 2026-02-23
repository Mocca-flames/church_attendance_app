import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/enums/contact_tag.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:church_attendance_app/features/contacts/presentation/providers/contact_provider.dart';
import 'package:church_attendance_app/features/contacts/presentation/widgets/contact_card.dart';
import 'package:church_attendance_app/features/contacts/screens/contact_detail_screen.dart';
import 'package:church_attendance_app/features/contacts/screens/contact_edit_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contact List Screen with search, filter, and CRUD operations.
class ContactListScreen extends ConsumerStatefulWidget {
  const ContactListScreen({super.key});

  @override
  ConsumerState<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends ConsumerState<ContactListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();
  
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchExpanded = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(contactListProvider);
    await ref.read(contactListProvider.future);
  }

  void _navigateToDetail(Contact contact) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ContactDetailScreen(contact: contact),
      ),
    );
  }

  void _navigateToCreate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ContactEditScreen(),
      ),
    );
  }

  void _onSearchChanged(String query) {
    ref.read(contactSearchProvider.notifier).search(query);
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(contactSearchProvider.notifier).clear();
  }

  void _toggleTagFilter(ContactTag tag) {
    final currentTag = ref.read(contactTagFilterProvider).selectedTag;
    if (currentTag == tag.value) {
      ref.read(contactTagFilterProvider.notifier).clear();
    } else {
      ref.read(contactTagFilterProvider.notifier).setTag(tag.value);
    }
  }

  Future<void> _importVcfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['vcf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.single.path;
        if (filePath != null && mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              content: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 20),
                  Text('Importing contacts...'),
                ],
              ),
            ),
          );

          final importResult = await ref.read(contactNotifierProvider.notifier).importVcfFile(filePath);

          if (mounted) Navigator.of(context).pop();

          if (importResult != null && mounted) {
            _showImportResultDialog(importResult);
            ref.invalidate(contactListProvider);
          } else if (mounted) {
            final error = ref.read(contactNotifierProvider).error;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error ?? 'Failed to import VCF file'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImportResultDialog(Map<String, dynamic> result) {
    final success = result['success'] as bool? ?? false;
    final importedCount = result['imported_count'] as int? ?? 0;
    final failedCount = result['failed_count'] as int? ?? 0;
    final errors = (result['errors'] as List<dynamic>?)?.cast<String>() ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle_outline : Icons.warning_amber_rounded,
              color: success ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(
              success ? 'Import Complete' : 'Import Issues',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResultRow('Imported', '$importedCount', Colors.green),
              if (failedCount > 0) ...[
                const SizedBox(height: 8),
                _buildResultRow('Failed', '$failedCount', Colors.red),
              ],
              if (errors.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: errors.map((error) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $error', style: const TextStyle(fontSize: 12)),
                    )).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(contactSearchProvider);
    final tagFilterState = ref.watch(contactTagFilterProvider);
    final contactsAsync = ref.watch(contactListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.primary,
        shape: const Border(bottom: BorderSide(color: Colors.white10, width: 1)),
        title: _isSearchExpanded
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  // Add search icon prefix
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
                onChanged: _onSearchChanged,
              )
            : const Text(
                'Contacts',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
        centerTitle: false,
        foregroundColor: Colors.white,
        actions: [
          if (!_isSearchExpanded)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search',
              onPressed: () {
                if (_searchController.text.isNotEmpty) {
                  _clearSearch();
                }
                setState(() {
                  _isSearchExpanded = true;
                });
                _searchFocusNode.requestFocus();
              },
            ),
          if (_isSearchExpanded)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearchExpanded = false;
                });
                _searchFocusNode.unfocus();
                _clearSearch();
              },
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            color: Colors.white,
            onSelected: (value) {
              if (value == 'import_vcf') {
                _importVcfFile();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import_vcf',
                child: Row(
                  children: [
                    Icon(Icons.upload_file_outlined, color: Colors.black87),
                    SizedBox(width: 12),
                    Text('Import VCF File'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
              ),
            ),
            child: _buildFilterChips(tagFilterState.selectedTag),
          ),
          
          // Contact List
          Expanded(
            child: _buildContactList(
              contactsAsync: contactsAsync,
              searchState: searchState,
              selectedTag: tagFilterState.selectedTag,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'contacts_fab',
        onPressed: _navigateToCreate,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.contactsColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.contactsColor, width: 1.5),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChips(String? selectedTag) {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM, vertical: 12),
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildStyledChip(
              label: 'All',
              isSelected: selectedTag == null,
              color: AppColors.primary,
              onTap: () => ref.read(contactTagFilterProvider.notifier).clear(),
            ),
          ),
          // Tag chips
          ...ContactTag.values.map((tag) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildStyledChip(
              label: tag.displayName,
              icon: tag.icon,
              isSelected: selectedTag == tag.value,
              color: tag.color,
              onTap: () => _toggleTagFilter(tag),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStyledChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? color : Colors.grey,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactList({
    required AsyncValue<List<Contact>> contactsAsync,
    required ContactSearchState searchState,
    String? selectedTag,
  }) {
    // Show search results if searching
    if (searchState.query.isNotEmpty) {
      return _buildSearchResults(searchState);
    }

    return contactsAsync.when(
      data: (contacts) {
        final filteredContacts = selectedTag != null
            ? contacts.where((c) => c.hasTag(selectedTag) && !c.isDeleted).toList()
            : contacts.where((c) => !c.isDeleted).toList();

        if (filteredContacts.isEmpty) {
          return _buildEmptyState(selectedTag != null);
        }

        return RefreshIndicator(
          key: _refreshKey,
          onRefresh: _handleRefresh,
          color: AppColors.primary,
          backgroundColor: Colors.white,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.paddingS, 
              AppDimens.paddingS, 
              AppDimens.paddingS, 
              40
            ),
            itemCount: filteredContacts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final contact = filteredContacts[index];
              return ContactCard(
                contact: contact,
                onTap: () => _navigateToDetail(contact),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildSearchResults(ContactSearchState searchState) {
    if (searchState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (searchState.error != null) {
      return _buildErrorState(searchState.error!);
    }

    final filteredResults = searchState.results.where((c) => !c.isDeleted).toList();

    if (filteredResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: AppDimens.paddingM),
            Text(
              'No contacts found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.paddingS, 
        AppDimens.paddingS, 
        AppDimens.paddingS, 
        40
      ),
      itemCount: filteredResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final contact = filteredResults[index];
        return ContactCard(
          contact: contact,
          onTap: () => _navigateToDetail(contact),
        );
      },
    );
  }

  Widget _buildEmptyState(bool hasFilter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilter ? Icons.filter_alt_off_outlined : Icons.person_add_alt_1_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: AppDimens.paddingM),
          Text(
            hasFilter ? 'No contacts with this tag' : 'No contacts yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimens.paddingS),
          Text(
            hasFilter
                ? 'Try selecting a different filter'
                : 'Tap + to add your first contact',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[300]),
            const SizedBox(height: AppDimens.paddingM),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingL),
            OutlinedButton(
              onPressed: _handleRefresh,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}