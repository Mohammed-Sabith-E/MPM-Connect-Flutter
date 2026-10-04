import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/providers/app_providers.dart';
import 'core/navigation/app_router.dart';
import 'shared/widgets/connectivity_wrapper.dart';

import 'core/utils/app_toast.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('.env file load notice: $e');
  }

  // Set system UI overlay style for Android (Deep Navy status bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.canvasBackground,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase and enable optimized offline persistence & cache
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Cache queries on device with unlimited cache size for instant offline retrieval
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  runApp(const ProviderScope(child: MpmConnectApp()));
}

class MpmConnectApp extends ConsumerStatefulWidget {
  const MpmConnectApp({super.key});

  @override
  ConsumerState<MpmConnectApp> createState() => _MpmConnectAppState();
}

class _MpmConnectAppState extends ConsumerState<MpmConnectApp> {

  /// All data providers that must be wiped when a different user logs in.
  /// This prevents user A's cached data from leaking into user B's session.
  void _invalidateAllDataProviders() {
    ref.invalidate(currentUserProfileProvider);
    ref.invalidate(currentOrgProvider);
    ref.invalidate(customersStreamProvider);
    ref.invalidate(transactionsStreamProvider);
    ref.invalidate(paymentsStreamProvider);
    ref.invalidate(salesmenStreamProvider);
    ref.invalidate(auditLogsStreamProvider);
    ref.invalidate(dashboardMetricsStreamProvider);
    ref.invalidate(businessSettingsProvider);
    ref.invalidate(customerRepositoryProvider);
    ref.invalidate(transactionRepositoryProvider);
    ref.invalidate(paymentRepositoryProvider);
    ref.invalidate(salesmanRepositoryProvider);
    ref.invalidate(dashboardRepositoryProvider);
    ref.invalidate(auditLogRepositoryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Watch auth state and invalidate ALL data providers when user UID changes.
    // This ensures user A's keepAlive-cached data is never shown to user B.
    ref.listen(authStateProvider, (previous, current) {
      final newUid = current.value?.uid;
      final prevUid = previous?.value?.uid;

      if (newUid != prevUid) {
        debugPrint('[Auth] User switched: $prevUid → $newUid — clearing all provider caches');
        _invalidateAllDataProviders();
      }
    });

    return MaterialApp.router(
      title: 'MPM Connect',
      scaffoldMessengerKey: AppToast.messengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => ConnectivityWrapper(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
