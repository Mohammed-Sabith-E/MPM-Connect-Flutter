import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mpm_connect/core/services/network_connectivity_service.dart';

class MockConnectivity implements Connectivity {
  final List<ConnectivityResult> _currentResults;

  MockConnectivity({List<ConnectivityResult>? results})
      : _currentResults = results ?? [ConnectivityResult.none];

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return _currentResults;
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      Stream.value(_currentResults);
}

void main() {
  group('NetworkConnectivityService Tests', () {
    test('detects offline when connectivity is none', () async {
      final mock = MockConnectivity(results: [ConnectivityResult.none]);
      final service = NetworkConnectivityService(connectivity: mock);

      final isOnline = await service.checkConnection();
      expect(isOnline, isFalse);
      expect(service.isCurrentlyOnline, isFalse);
    });

    test('initializes and provides connectivity stream', () async {
      final mock = MockConnectivity(results: [ConnectivityResult.none]);
      final service = NetworkConnectivityService(connectivity: mock);

      expect(service.onConnectivityChanged, isNotNull);
    });
  });
}
