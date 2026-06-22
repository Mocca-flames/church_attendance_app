import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectionStatus { online, offline }

class ConnectionStatusNotifier extends Notifier<ConnectionStatus> {
  int _failureCount = 0;
  static const int _failureThreshold = 3;

  @override
  ConnectionStatus build() => ConnectionStatus.online;

  void recordFailure() {
    _failureCount++;
    if (_failureCount >= _failureThreshold) {
      state = ConnectionStatus.offline;
    }
  }

  void recordSuccess() {
    _failureCount = 0;
    state = ConnectionStatus.online;
  }
}

final connectionStatusProvider =
    NotifierProvider<ConnectionStatusNotifier, ConnectionStatus>(
  ConnectionStatusNotifier.new,
);
