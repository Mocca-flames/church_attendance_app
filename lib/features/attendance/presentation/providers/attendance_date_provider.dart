import 'package:church_attendance_app/core/enums/service_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State class for attendance date and service type selection
class AttendanceDateState {
  final bool isPastDateMode;
  final DateTime selectedPastDate;
  final ServiceType selectedServiceType;

  const AttendanceDateState({
    required this.selectedPastDate, required this.selectedServiceType, this.isPastDateMode = false,
  });

  /// Factory constructor for initial "Today" mode state
  factory AttendanceDateState.today() {
    final now = DateTime.now();
    return AttendanceDateState(
      isPastDateMode: false,
      selectedPastDate: now,
      selectedServiceType: ServiceType.getServiceTypeByDay(now),
    );
  }

  AttendanceDateState copyWith({
    bool? isPastDateMode,
    DateTime? selectedPastDate,
    ServiceType? selectedServiceType,
  }) {
    return AttendanceDateState(
      isPastDateMode: isPastDateMode ?? this.isPastDateMode,
      selectedPastDate: selectedPastDate ?? this.selectedPastDate,
      selectedServiceType: selectedServiceType ?? this.selectedServiceType,
    );
  }

  /// Get the effective service date (today in "Today" mode, selected date in "Past Date" mode)
  DateTime get effectiveServiceDate {
    if (isPastDateMode) {
      return selectedPastDate;
    }
    return DateTime.now();
  }

  /// Get the effective service type (auto-detected in "Today" mode, manually selected in "Past Date" mode)
  ServiceType get effectiveServiceType {
    if (isPastDateMode) {
      return selectedServiceType;
    }
    return ServiceType.getServiceTypeByDay();
  }
}

/// Notifier for managing attendance date and service type selection
class AttendanceDateNotifier extends Notifier<AttendanceDateState> {
  @override
  AttendanceDateState build() {
    return AttendanceDateState.today();
  }

  /// Toggle between "Today" mode and "Past Date" mode
  void togglePastDateMode() {
    if (state.isPastDateMode) {
      // Switch back to Today mode
      state = AttendanceDateState.today();
    } else {
      // Switch to Past Date mode with default values
      state = state.copyWith(
        isPastDateMode: true,
        selectedPastDate: DateTime.now(),
        selectedServiceType: ServiceType.getServiceTypeByDay(),
      );
    }
  }

  /// Set the past date mode explicitly
  void setPastDateMode(bool isPastDateMode) {
    if (isPastDateMode) {
      // Initialize with default past date (today) if not already set
      if (!state.isPastDateMode) {
        state = state.copyWith(
          isPastDateMode: true,
          selectedPastDate: DateTime.now(),
          selectedServiceType: ServiceType.getServiceTypeByDay(),
        );
      }
    } else {
      // Switch back to Today mode
      state = AttendanceDateState.today();
    }
  }

  /// Update the selected past date
  void setSelectedPastDate(DateTime date) {
    state = state.copyWith(
      selectedPastDate: date,
      // Auto-update service type based on the new date
      selectedServiceType: ServiceType.getServiceTypeByDay(date),
    );
  }

  /// Manually set the service type (only applicable in Past Date mode)
  void setSelectedServiceType(ServiceType serviceType) {
    state = state.copyWith(selectedServiceType: serviceType);
  }

  /// Reset to Today mode
  void resetToToday() {
    state = AttendanceDateState.today();
  }
}

/// Provider for attendance date and service type selection
final attendanceDateProvider =
    NotifierProvider<AttendanceDateNotifier, AttendanceDateState>(() {
  return AttendanceDateNotifier();
});
