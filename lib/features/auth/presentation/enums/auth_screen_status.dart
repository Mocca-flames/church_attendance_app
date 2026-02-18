/// Smart enum for authentication screen status.
/// Represents the different states of auth screens.
enum AuthScreenStatus {
  initial,
  loading,
  success,
  error;

  /// Whether the screen is in loading state
  bool get isLoading => this == AuthScreenStatus.loading;

  /// Whether the screen has an error
  bool get hasError => this == AuthScreenStatus.error;

  /// Whether the operation is in progress
  bool get isInProgress => this == AuthScreenStatus.loading || this == AuthScreenStatus.initial;
}