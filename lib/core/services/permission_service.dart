/// Application Roles and Permission Rules
enum UserRole {
  superAdmin('Super Admin'),
  admin('Admin'),
  manager('Manager'),
  salesman('Salesman'),
  cashier('Cashier');

  final String label;
  const UserRole(this.label);

  static UserRole fromString(String? roleStr) {
    switch (roleStr?.toLowerCase().trim()) {
      case 'superadmin':
      case 'super_admin':
      case 'super admin':
        return UserRole.superAdmin;
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'salesman':
        return UserRole.salesman;
      case 'cashier':
        return UserRole.cashier;
      default:
        return UserRole.salesman;
    }
  }
}

/// Centralized Role & Permission Service
class PermissionService {
  PermissionService._();

  // Dashboard Access
  static bool canViewFullDashboard(UserRole role) =>
      role == UserRole.admin || role == UserRole.manager;

  static bool canViewAssignedDashboard(UserRole role) => true;

  // Customer Module
  static bool canViewAllCustomers(UserRole role) =>
      role == UserRole.admin || role == UserRole.manager || role == UserRole.cashier;

  static bool canCreateCustomer(UserRole role) =>
      role == UserRole.admin || role == UserRole.manager || role == UserRole.salesman;

  static bool canBulkImportCustomers(UserRole role) =>
      role == UserRole.admin || role == UserRole.manager || role == UserRole.salesman;

  static bool canEditCustomer(UserRole role) =>
      role == UserRole.admin || role == UserRole.manager;

  static bool canDeleteCustomer(UserRole role) => role == UserRole.admin;

  // Transactions / Invoices Module
  static bool canCreateTransaction(UserRole role) =>
      role == UserRole.admin ||
      role == UserRole.manager ||
      role == UserRole.salesman ||
      role == UserRole.cashier;

  static bool canViewAllTransactions(UserRole role) =>
      role == UserRole.admin || role == UserRole.manager || role == UserRole.cashier;

  static bool canEditTransaction(UserRole role) =>
      role == UserRole.admin || role == UserRole.manager;

  // Payment / Settlement Module
  static bool canRecordPayment(UserRole role) =>
      role == UserRole.admin || role == UserRole.manager || role == UserRole.cashier;

  static bool canViewPaymentHistory(UserRole role) =>
      role == UserRole.admin || role == UserRole.manager || role == UserRole.cashier;

  // Salesmen Module
  static bool canManageSalesmen(UserRole role) =>
      role == UserRole.admin || role == UserRole.manager;

  // Users Module (Admin-Only)
  static bool canManageUsers(UserRole role) => role == UserRole.admin;

  // Audit Logs (Admin-Only)
  static bool canViewAuditLogs(UserRole role) => role == UserRole.admin;

  // Reports
  static bool canViewReports(UserRole role) =>
      role == UserRole.admin || role == UserRole.manager;

  // System Settings
  static bool canManageSettings(UserRole role) => role == UserRole.admin;
}
