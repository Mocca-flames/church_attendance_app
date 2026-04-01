# Full Statistics Screen - Implementation Plan

## Overview

Create a new dedicated **Full Statistics Screen** accessible from the More menu (`lib/features/more/presentation/screen/statistics_screen.dart`). This screen provides comprehensive, detailed statistics based on the `/contacts/dashboard/statistics` endpoint with full date range filtering capabilities.

---

## 1. Location & Navigation

### File Location
- **Screen**: `lib/features/more/presentation/screen/statistics_screen.dart`

### Navigation Entry Point
Add a new menu item in [`more_screen.dart`](lib/features/more/presentation/screen/more_screen.dart:106) under "Data Management" section:
```dart
ListTile(
  leading: Container(
    padding: const EdgeInsets.all(AppDimens.paddingS),
    decoration: BoxDecoration(
      color: AppColors.cyan500.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(AppDimens.radiusM),
    ),
    child: const Icon(Icons.analytics, color: AppColors.cyan500),
  ),
  title: const Text('Full Statistics'),
  subtitle: const Text('Detailed analytics with date filters'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StatisticsScreen()),
    );
  },
),
```

---

## 2. Data Model (Extended DashboardStatistics)

Update [`dashboard_providers.dart`](lib/features/home/presentation/providers/dashboard_providers.dart:1) to include full response parsing:

```dart
class FullDashboardStatistics {
  final int totalContacts;
  final CountData newContacts;
  final CountData modifiedContacts;
  final Map<String, int> locations;
  final Map<String, int> roles;
  final MembershipData membership;
}

class CountData {
  final int count;
  final String? dateFrom;
  final String? dateTo;
}

class MembershipData {
  final int member;
  final int nonMember;
}
```

### New Provider
```dart
final fullStatisticsProvider = FutureProvider<FullDashboardStatistics?>((ref) async {
  ref.watch(statisticsRefreshTriggerProvider);
  
  final isOnline = ref.watch(isOnlineProvider);
  if (!isOnline) return null;
  
  // Get date range from filter state
  final dateRange = ref.watch(selectedDateRangeProvider);
  
  try {
    final dioClient = ref.read(dioClientProvider);
    final response = await dioClient.getDashboardStatistics(
      dateFrom: dateRange?.start.toIso8601String(),
      dateTo: dateRange?.end.toIso8601String(),
    );
    
    if (response.statusCode == 200 && response.data != null) {
      return FullDashboardStatistics.fromJson(response.data);
    }
    return null;
  } catch (e) {
    return null;
  }
});
```

---

## 3. Screen Architecture

### 3.1 Layout Structure

```
┌─────────────────────────────────────────┐
│  AppBar: "Full Statistics"             │
├─────────────────────────────────────────┤
│  ┌───────────────────────────────────┐  │
│  │  Date Range Filter Card          │  │
│  │  [From Date] → [To Date] [Apply]  │  │
│  │  Quick filters: Today | Week |    │  │
│  │  Month | Quarter | Year | Custom   │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  Overview Stats Cards Row         │  │
│  │  [Total] [New] [Modified]         │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  Locations Chart Section          │  │
│  │  - Horizontal bar chart           │  │
│  │  - Shows all location counts     │  │
│  │  - Sorted by count descending     │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  Roles Chart Section             │  │
│  │  - Radar chart for role dist.     │  │
│  │  - Shows all role counts         │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  Membership Section              │  │
│  │  - Pie chart (Member/Non-Member)  │  │
│  │  - Percentage breakdown           │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  Detailed Breakdown Cards        │  │
│  │  - Locations breakdown table     │  │
│  │  - Roles breakdown table         │  │
│  │  - Membership breakdown          │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### 3.2 Visual Design

**Follow Existing UI/UX Philosophy:**
- Use `Card` with `borderRadius: AppDimens.radiusL`
- Use existing `AppColors` (cyan, purple, green, red)
- Padding: `AppDimens.paddingM`
- Use glass-style widgets where appropriate
- Follow the same card styling as [`home_screen.dart`](lib/features/home/presentation/screens/home_screen.dart:784)

**Color Coding:**
| Category | Color | Icon |
|----------|-------|------|
| Locations | `Colors.red.shade700` | `Icons.location_on` |
| Roles | `Colors.purple.shade700` | `Icons.work` |
| Membership | `Colors.green.shade700` | `Icons.person` |
| New Contacts | `Colors.blue` | `Icons.person_add` |
| Modified | `Colors.orange` | `Icons.edit` |
| Total | `Colors.cyan` | `Icons.people` |

### 3.3 Date Range Filter Widget

EASE-compliant date selection following your app's philosophy:

```dart
Widget _buildDateRangeFilter(BuildContext context, WidgetRef ref) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Icon(Icons.date_range, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppDimens.paddingS),
              Text('Filter by Date', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppDimens.paddingM),
          
          // Date inputs row
          Row(
            children: [
              Expanded(child: _buildDatePicker('From', dateFrom, ...)),
              const SizedBox(width: AppDimens.paddingM),
              Expanded(child: _buildDatePicker('To', dateTo, ...)),
            ],
          ),
          
          const SizedBox(height: AppDimens.paddingM),
          
          // Quick filter chips
          Wrap(
            spacing: 8,
            children: [
              _QuickFilterChip('Today', () => selectToday()),
              _QuickFilterChip('This Week', () => selectThisWeek()),
              _QuickFilterChip('This Month', () => selectThisMonth()),
              _QuickFilterChip('This Quarter', () => selectThisQuarter()),
              _QuickFilterChip('This Year', () => selectThisYear()),
              _QuickFilterChip('All Time', () => selectAllTime()),
            ],
          ),
          
          const SizedBox(height: AppDimens.paddingM),
          
          // Apply button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => applyFilter(),
              child: const Text('Apply Filter'),
            ),
          ),
        ],
      ),
    ),
  );
}
```

---

## 4. Component Breakdown

### 4.1 Overview Stats Cards Row
Based on [`_QuickStatCard`](lib/features/home/presentation/screens/home_screen.dart:1607) pattern:
- 3 cards in a Row: Total Contacts, New Contacts, Modified Contacts
- Each with icon, value, and label
- Responsive spacing based on screen width

### 4.2 Locations Section Card
- Header with location icon and "Locations" title
- Horizontal bar chart (reuse [`HorizontalBarChart`](lib/features/home/presentation/screens/home_screen.dart:1772) pattern)
- Full list of locations sorted by count
- Each bar shows location name, bar, and count

### 4.3 Roles Section Card  
- Header with work icon and "Roles" title
- Radar chart (reuse [`RoleRadarChart`](lib/features/home/presentation/screens/home_screen.dart:1946) pattern)
- All 6 roles: pastor, protocol, worshiper, usher, financier, servant

### 4.4 Membership Section Card
- Header with person icon and "Membership" title
- Pie chart (reuse [`MembershipPieChart`](lib/features/home/presentation/screens/home_screen.dart:1997) pattern)
- Member vs Non-Member breakdown with percentages

### 4.5 Detailed Breakdown Cards
Expandable sections showing:
- Each location with its count and percentage of total
- Each role with its count and percentage of total
- Membership with exact numbers

---

## 5. State Management

### Notifiers (add to dashboard_providers.dart)

```dart
/// Selected date range for statistics filter
class StatisticsDateRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null; // null means all time
  
  void setRange(DateTime start, DateTime end) {
    state = DateTimeRange(start: start, end: end);
  }
  
  void setToday() {
    final now = DateTime.now();
    state = DateTimeRange(start: now, end: now);
  }
  
  void setThisWeek() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    state = DateTimeRange(start: start, end: now);
  }
  
  void setThisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    state = DateTimeRange(start: start, end: now);
  }
  
  void setThisQuarter() {
    final now = DateTime.now();
    final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
    final start = DateTime(now.year, quarterMonth, 1);
    state = DateTimeRange(start: start, end: now);
  }
  
  void setThisYear() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    state = DateTimeRange(start: start, end: now);
  }
  
  void setAllTime() {
    state = null;
  }
}

final selectedDateRangeProvider = NotifierProvider<StatisticsDateRangeNotifier, DateTimeRange?>(() {
  return StatisticsDateRangeNotifier();
});

/// Refresh trigger for statistics
class StatisticsRefreshTriggerNotifier extends Notifier<int> {
  @override
  int build() => 0;
  
  void triggerRefresh() => state = state + 1;
}

final statisticsRefreshTriggerProvider = NotifierProvider<StatisticsRefreshTriggerNotifier, int>(() {
  return StatisticsRefreshTriggerNotifier();
});
```

---

## 6. Implementation Checklist

### Phase 1: Setup & Navigation
- [ ] Create `statistics_screen.dart` file
- [ ] Add navigation entry in `more_screen.dart`
- [ ] Create date range state providers in `dashboard_providers.dart`

### Phase 2: Data Layer
- [ ] Extend `FullDashboardStatistics` data class
- [ ] Create `fullStatisticsProvider` with date filter support
- [ ] Update `dioClient.getDashboardStatistics()` usage

### Phase 3: UI Components
- [ ] Build date range filter card with quick filters
- [ ] Build overview stats row (3 cards)
- [ ] Build locations section with horizontal bar chart
- [ ] Build roles section with radar chart
- [ ] Build membership section with pie chart
- [ ] Build detailed breakdown cards (expandable)

### Phase 4: Integration
- [ ] Connect providers to UI
- [ ] Handle loading states
- [ ] Handle error states
- [ ] Handle offline state

---

## 7. Dependencies & Reuse

### Existing Widgets to Reuse
| Widget | Location | Purpose |
|--------|----------|---------|
| `HorizontalBarChart` | home_screen.dart:1772 | Location bars |
| `RoleRadarChart` | home_screen.dart:1946 | Role radar |
| `MembershipPieChart` | home_screen.dart:1997 | Member pie |
| `GlassCard` | glass_card.dart | Card styling |
| `DynamicBackground` | gradient_background.dart | Background |
| `AppDimens` | app_constants.dart | Spacing |
| `AppColors` | app_colors.dart | Colors |

### Existing Providers to Extend
| Provider | Location | Notes |
|----------|----------|-------|
| `dioClientProvider` | dio_client.dart | Already has date params |
| `isOnlineProvider` | sync_manager_provider.dart | Check connectivity |

---

## 8. Endpoints

The screen uses `GET /contacts/dashboard/statistics` with optional query parameters:

| Parameter | Type | Description |
|-----------|------|-------------|
| `date_from` | ISO 8601 datetime | Start date filter |
| `date_to` | ISO 8601 datetime | End date filter |

Example:
```
GET /contacts/dashboard/statistics?date_from=2024-01-01&date_to=2024-01-31
```

---

## 9. EASE Principle

The screen embodies EASE (EASY) principles:
- **E**vident: Clear date filters with visual feedback
- **A**ccessible: Large tap targets, clear labels
- **S**imple: One clear action per section
- **Y**ours: Follows existing app patterns and styling

Date filters make statistics easy to explore:
- Quick filter chips for common ranges
- Custom date pickers for specific needs
- Clear visual indication of selected range
- Instant apply for responsive experience