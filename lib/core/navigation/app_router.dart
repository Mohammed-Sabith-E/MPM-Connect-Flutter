import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/app_providers.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/customers/screens/customers_list_screen.dart';
import '../../features/customers/screens/customer_detail_screen.dart';
import '../../features/customers/screens/add_edit_customer_screen.dart';
import '../../features/customers/screens/contact_picker_screen.dart';
import '../../features/customers/screens/import_preview_screen.dart';
import '../../features/customers/services/customer_import_service.dart';
import '../../features/transactions/screens/new_transaction_screen.dart';
import '../../features/transactions/screens/transactions_list_screen.dart';
import '../../features/transactions/screens/transaction_detail_screen.dart';
import '../../features/payments/screens/payment_history_screen.dart';
import '../../features/salesmen/screens/salesmen_screen.dart';
import '../../features/salesmen/screens/add_salesman_screen.dart';
import '../../features/users/screens/users_screen.dart';
import '../../features/logs/screens/audit_logs_screen.dart';
import '../../features/reports/screens/reports_hub_screen.dart';
import '../../features/super_admin/screens/super_admin_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../shared/screens/no_internet_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final user = authState.asData?.value;
      final isLoggedIn = user != null;
      final isSplash = state.matchedLocation == '/splash';
      final isLoggingIn = state.matchedLocation == '/login';

      // 1. While auth state is initializing from storage, keep on splash screen
      if (isLoading) {
        return isSplash ? null : '/splash';
      }

      // 2. Not logged in -> redirect to login
      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      // 3. Logged in as Super Admin -> redirect to /super-admin
      if (user.isSuperAdmin) {
        if (state.matchedLocation != '/super-admin') {
          return '/super-admin';
        }
        return null;
      }

      // 4. Logged in as Admin or Salesman -> redirect to /dashboard
      if (isLoggingIn || isSplash || state.matchedLocation == '/super-admin') {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/super-admin',
        builder: (context, state) => const SuperAdminScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/customers',
        builder: (context, state) => const CustomersListScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) {
              final extraMap = state.extra as Map<String, dynamic>?;
              final initialName = extraMap?['initialName'] as String? ?? state.uri.queryParameters['initialName'];
              final initialPhone = extraMap?['initialPhone'] as String? ?? state.uri.queryParameters['initialPhone'];
              return AddEditCustomerScreen(
                initialName: initialName,
                initialPhone: initialPhone,
              );
            },
          ),
          GoRoute(
            path: 'import-picker',
            builder: (context, state) {
              final isMultiSelect = (state.extra as bool?) ?? true;
              return ContactPickerScreen(isMultiSelect: isMultiSelect);
            },
          ),
          GoRoute(
            path: 'import-preview',
            builder: (context, state) {
              final rawItems = (state.extra as List<RawImportItem>?) ?? [];
              return ImportPreviewScreen(rawItems: rawItems);
            },
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AddEditCustomerScreen(customerId: id);
            },
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CustomerDetailScreen(customerId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/transactions',
        builder: (context, state) => const TransactionsListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) {
              final customerId = state.uri.queryParameters['customerId'];
              return NewTransactionScreen(preselectedCustomerId: customerId);
            },
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TransactionDetailScreen(transactionId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/payments',
        builder: (context, state) => const PaymentHistoryScreen(),
      ),
      GoRoute(
        path: '/salesmen',
        builder: (context, state) => const SalesmenScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddSalesmanScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/users',
        builder: (context, state) => const UsersScreen(),
      ),
      GoRoute(
        path: '/logs',
        builder: (context, state) => const AuditLogsScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsHubScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/no-internet',
        builder: (context, state) => const NoInternetScreen(),
      ),
    ],
  );
});
