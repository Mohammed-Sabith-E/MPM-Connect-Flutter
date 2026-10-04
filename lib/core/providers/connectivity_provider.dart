import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/network_connectivity_service.dart';

/// Provider for the singleton NetworkConnectivityService
final networkConnectivityServiceProvider = Provider<NetworkConnectivityService>((ref) {
  final service = NetworkConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Real-time stream of internet connectivity status (true = online, false = offline)
final connectivityStatusStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(networkConnectivityServiceProvider);
  return service.onConnectivityChanged;
});

/// Current online status with immediate default true (preventing startup flicker)
final isOnlineProvider = Provider<bool>((ref) {
  final asyncStatus = ref.watch(connectivityStatusStreamProvider);
  return asyncStatus.valueOrNull ?? ref.read(networkConnectivityServiceProvider).isCurrentlyOnline;
});
