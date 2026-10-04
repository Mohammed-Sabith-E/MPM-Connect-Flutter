import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for monitoring and checking internet connectivity.
/// Combines network interface status (WiFi / Mobile Data) with a lightweight DNS lookup
/// to guarantee true internet reachability.
class NetworkConnectivityService {
  final Connectivity _connectivity;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _lastKnownStatus = true;

  NetworkConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  /// Broadcast stream of internet connectivity status (true = online, false = offline)
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  /// Returns the last known online status
  bool get isCurrentlyOnline => _lastKnownStatus;

  void _init() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      final isOnline = await _verifyInternetAccess(results);
      if (isOnline != _lastKnownStatus) {
        _lastKnownStatus = isOnline;
        _connectivityController.add(isOnline);
      }
    });

    // Initial check
    checkConnection();
  }

  /// Manually checks for active internet connection
  Future<bool> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final isOnline = await _verifyInternetAccess(results);
      if (isOnline != _lastKnownStatus) {
        _lastKnownStatus = isOnline;
        _connectivityController.add(isOnline);
      }
      return isOnline;
    } catch (e) {
      debugPrint('NetworkConnectivityService error: $e');
      return false;
    }
  }

  /// Verifies whether the connectivity result actually has internet access
  Future<bool> _verifyInternetAccess(List<ConnectivityResult> results) async {
    final hasInterface = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn ||
        r == ConnectivityResult.other);

    if (!hasInterface) {
      return false;
    }

    // In web/test or if platform doesn't support raw socket lookup, trust interface
    if (kIsWeb) {
      return true;
    }

    try {
      final lookup = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 3),
        onTimeout: () => [],
      );
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      // Fallback check against root DNS server if domain lookup failed
      try {
        final socket = await Socket.connect(
          '8.8.8.8',
          53,
          timeout: const Duration(seconds: 2),
        );
        socket.destroy();
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}
