import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../../core/services/permission_service.dart';
import '../../logs/repositories/audit_log_repository.dart';

class AuthRepository {
  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepo;

  static const String _sessionKey = 'active_user_id';
  static const String _cachedUserKey = 'cached_user_profile_json';
  final StreamController<AppUser?> _authStateController =
      StreamController<AppUser?>.broadcast();

  AuthRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepo,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auditLogRepo = auditLogRepo ?? AuditLogRepository(firestore: firestore) {
    // Attempt automatic session restoration on repository creation
    restoreSession();
  }

  /// Broadcast stream of current authenticated user (pure Firestore / local session)
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  static String get superAdminEmail {
    try {
      if (dotenv.isInitialized) {
        return dotenv.env['SUPER_ADMIN_EMAIL']?.trim() ?? 'superadmin@gmail.com';
      }
    } catch (_) {}
    return 'superadmin@gmail.com';
  }

  static String get superAdminPassword {
    try {
      if (dotenv.isInitialized) {
        return dotenv.env['SUPER_ADMIN_PASSWORD']?.trim() ?? 'super123';
      }
    } catch (_) {}
    return 'super123';
  }

  /// Restores session from SharedPreferences
  Future<AppUser?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeUid = prefs.getString(_sessionKey);

      if (activeUid == null || activeUid.isEmpty) {
        _authStateController.add(null);
        return null;
      }

      if (activeUid == 'super_admin_id') {
        final superUser = AppUser.superAdmin(email: superAdminEmail);
        _authStateController.add(superUser);
        return superUser;
      }

      // Fast-path: immediately emit cached user so UI never flashes
      final cachedJson = prefs.getString(_cachedUserKey);
      AppUser? cachedUser;
      if (cachedJson != null) {
        try {
          final map = jsonDecode(cachedJson) as Map<String, dynamic>;
          cachedUser = AppUser.fromMap(map, activeUid);
          _authStateController.add(cachedUser);
        } catch (_) {}
      }

      final doc = await _firestore.collection('users').doc(activeUid).get();
      if (!doc.exists || doc.data() == null) {
        await prefs.remove(_sessionKey);
        await prefs.remove(_cachedUserKey);
        _authStateController.add(null);
        return null;
      }

      final user = AppUser.fromMap(doc.data()!, doc.id);
      if (!user.isActive) {
        await prefs.remove(_sessionKey);
        await prefs.remove(_cachedUserKey);
        _authStateController.add(null);
        return null;
      }

      try {
        await prefs.setString(_cachedUserKey, jsonEncode(user.toMap()));
      } catch (_) {}

      _authStateController.add(user);
      return user;
    } catch (_) {
      _authStateController.add(null);
      return null;
    }
  }

  /// Fetches current user profile from Firestore or active session
  Future<AppUser?> getCurrentUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final activeUid = prefs.getString(_sessionKey);
    if (activeUid == null) return null;

    if (activeUid == 'super_admin_id') {
      return AppUser.superAdmin(email: superAdminEmail);
    }

    final doc = await _firestore.collection('users').doc(activeUid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromMap(doc.data()!, doc.id);
  }

  /// Checks if an email is already registered globally (Super Admin or any user in Firestore)
  Future<bool> isEmailRegistered(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail == superAdminEmail.toLowerCase()) {
      return true;
    }

    final snap = await _firestore
        .collection('users')
        .where('email', isEqualTo: cleanEmail)
        .limit(1)
        .get();

    return snap.docs.isNotEmpty;
  }

  /// Sign In with Email & Password using Firestore only
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    // 1. Check Super Admin credentials
    if (cleanEmail == superAdminEmail.toLowerCase()) {
      if (cleanPassword != superAdminPassword) {
        throw Exception('Invalid email or password');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, 'super_admin_id');

      final superUser = AppUser.superAdmin(email: superAdminEmail);
      _authStateController.add(superUser);
      return superUser;
    }

    // 2. Query Firestore users collection for matching email
    final snap = await _firestore
        .collection('users')
        .where('email', isEqualTo: cleanEmail)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw Exception('Invalid email or password');
    }

    final doc = snap.docs.first;
    final data = doc.data();

    // Verify password
    final storedPassword = data['password'] as String?;
    if (storedPassword == null || storedPassword != cleanPassword) {
      throw Exception('Invalid email or password');
    }

    final appUser = AppUser.fromMap(data, doc.id);

    // Verify active status
    if (!appUser.isActive) {
      throw Exception('This account has been disabled. Please contact the administrator.');
    }

    // Verify organization exists and is valid
    final orgId = appUser.organizationId.trim();
    if (orgId.isEmpty) {
      throw Exception('Your account is not assigned to an organization.');
    }

    final orgDoc = await _firestore.collection('organizations').doc(orgId).get();
    if (!orgDoc.exists || orgDoc.data() == null) {
      throw Exception('Your account is not assigned to an organization.');
    }

    // Save active session in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, doc.id);
    try {
      await prefs.setString(_cachedUserKey, jsonEncode(appUser.toMap()));
    } catch (_) {}

    // Update lastLoginAt
    await _firestore.collection('users').doc(doc.id).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });

    try {
      await _auditLogRepo.logAction(
        userId: doc.id,
        userName: appUser.name,
        action: 'LOGIN',
        module: 'Auth',
        entityId: doc.id,
        description: '${appUser.name} logged in',
      );
    } catch (_) {}

    _authStateController.add(appUser);
    return appUser;
  }

  /// Super Admin creates a new Organization and its primary Admin user
  Future<Map<String, dynamic>> createOrganizationWithAdmin({
    required String organizationName,
    required String adminEmail,
    required String adminPassword,
    String? adminName,
    String? adminPhone,
  }) async {
    final cleanEmail = adminEmail.trim().toLowerCase();

    if (await isEmailRegistered(cleanEmail)) {
      throw Exception('This email is already registered.');
    }

    // Generate unique system ID format: org_<12 hexadecimal characters>
    final randomHex = List.generate(12, (_) => math.Random().nextInt(16).toRadixString(16)).join();
    final orgId = 'org_$randomHex';

    // 1. Create Organization in organizations/{orgId}
    final orgDoc = _firestore.collection('organizations').doc(orgId);
    await orgDoc.set({
      'organizationId': orgId,
      'name': organizationName.trim(),
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Create Admin user in users/{userId}
    final userDoc = _firestore.collection('users').doc();
    final displayName = (adminName != null && adminName.trim().isNotEmpty)
        ? adminName.trim()
        : 'Admin';

    final adminUser = AppUser(
      uid: userDoc.id,
      name: displayName,
      email: cleanEmail,
      phone: adminPhone?.trim() ?? '',
      password: adminPassword.trim(),
      organizationId: orgId,
      role: UserRole.admin,
      status: 'active',
      isActive: true,
      createdAt: DateTime.now(),
      createdBy: 'super_admin',
    );

    await userDoc.set(adminUser.toMap());

    // Also mirror to organizations/{orgId}/users/{userId}
    await orgDoc.collection('users').doc(userDoc.id).set(adminUser.toMap());

    return {
      'organizationId': orgId,
      'admin': adminUser,
    };
  }

  /// Organization Admin creates a new user (e.g. Salesman) inside their organization
  Future<AppUser> adminCreateUser({
    required String adminUid,
    required String adminName,
    required String adminOrgId,
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (await isEmailRegistered(cleanEmail)) {
      throw Exception('This email is already registered.');
    }

    final userDoc = _firestore.collection('users').doc();
    final appUser = AppUser(
      uid: userDoc.id,
      name: name.trim(),
      email: cleanEmail,
      phone: phone.trim(),
      password: password.trim(),
      organizationId: adminOrgId,
      role: role,
      status: 'active',
      isActive: true,
      createdAt: DateTime.now(),
      createdBy: adminUid,
    );

    // 1. Root users collection (for login & email lookup)
    await userDoc.set(appUser.toMap());

    // 2. Organization-scoped users subcollection
    await _firestore
        .collection('organizations')
        .doc(adminOrgId)
        .collection('users')
        .doc(userDoc.id)
        .set(appUser.toMap());

    // Log action
    try {
      await _auditLogRepo.logAction(
        userId: adminUid,
        userName: adminName,
        action: 'CREATE_USER',
        module: 'Users',
        entityId: userDoc.id,
        description: '$adminName created user $name with role ${role.label}',
      );
    } catch (_) {}

    return appUser;
  }

  /// Updates user status (active / inactive)
  Future<void> setUserActiveStatus({
    required String adminUid,
    required String adminName,
    required String organizationId,
    required String targetUserId,
    required String targetUserName,
    required bool isActive,
  }) async {
    final statusStr = isActive ? 'active' : 'inactive';

    await _firestore.collection('users').doc(targetUserId).update({
      'isActive': isActive,
      'status': statusStr,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    try {
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('users')
          .doc(targetUserId)
          .update({
        'isActive': isActive,
        'status': statusStr,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    try {
      await _auditLogRepo.logAction(
        userId: adminUid,
        userName: adminName,
        action: isActive ? 'ENABLE_USER' : 'DISABLE_USER',
        module: 'Users',
        entityId: targetUserId,
        description: '$adminName ${isActive ? "activated" : "deactivated"} user $targetUserName',
      );
    } catch (_) {}
  }

  /// Sign Out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_cachedUserKey);
    _authStateController.add(null);
  }
}
