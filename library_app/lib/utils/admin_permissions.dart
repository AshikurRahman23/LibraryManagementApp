import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Admin permission keys - must match backend
class AdminPermissionKeys {
  static const String manageBooks = 'manage_books';
  static const String deleteStudent = 'delete_student';
  static const String approveRequests = 'approve_requests';
  static const String manageLoans = 'manage_loans';
  static const String manageSuggestions = 'manage_suggestions';
  
  /// All available permissions
  static const List<String> all = [
    manageBooks,
    deleteStudent,
    approveRequests,
    manageLoans,
    manageSuggestions,
  ];
}

/// Service to manage admin permissions
class AdminPermissionService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _permissionsKey = 'admin_permissions';
  
  static List<String> _cachedPermissions = [];
  static bool _isLoaded = false;
  
  /// Check if permissions have been loaded
  static bool get isLoaded => _isLoaded;
  
  /// Save permissions to secure storage
  static Future<void> savePermissions(List<dynamic> permissions) async {
    final permList = permissions.map((e) => e.toString()).toList();
    await _storage.write(key: _permissionsKey, value: jsonEncode(permList));
    _cachedPermissions = permList;
    _isLoaded = true;
    debugPrint('[AdminPermissions] Saved permissions: $permList');
  }
  
  /// Load permissions from secure storage
  static Future<List<String>> loadPermissions() async {
    if (_isLoaded && _cachedPermissions.isNotEmpty) return _cachedPermissions;
    
    final stored = await _storage.read(key: _permissionsKey);
    debugPrint('[AdminPermissions] Loading from storage: $stored');
    if (stored != null && stored.isNotEmpty) {
      try {
        _cachedPermissions = List<String>.from(jsonDecode(stored));
        debugPrint('[AdminPermissions] Loaded permissions: $_cachedPermissions');
      } catch (e) {
        debugPrint('[AdminPermissions] Parse error: $e');
        _cachedPermissions = [];
      }
    } else {
      _cachedPermissions = [];
    }
    _isLoaded = true;
    return _cachedPermissions;
  }
  
  /// Get cached permissions (must call loadPermissions first)
  static List<String> get permissions => _cachedPermissions;
  
  /// Check if admin has a specific permission
  static Future<bool> hasPermission(String permission) async {
    final perms = await loadPermissions();
    return perms.contains(permission);
  }
  
  /// Check if admin has permission (sync - uses cache)
  /// Returns false if not loaded yet or no permission
  static bool hasPermissionSync(String permission) {
    // If not loaded yet, default to false (no action buttons)
    if (!_isLoaded) {
      return false;
    }
    return _cachedPermissions.contains(permission);
  }
  
  /// Check if admin can manage books (add, edit)
  static bool get canManageBooks => hasPermissionSync(AdminPermissionKeys.manageBooks);
  
  /// Check if admin can delete students
  static bool get canDeleteStudent => hasPermissionSync(AdminPermissionKeys.deleteStudent);
  
  /// Check if admin can approve/reject requests
  static bool get canApproveRequests => hasPermissionSync(AdminPermissionKeys.approveRequests);
  
  /// Check if admin can manage loans (issue, return)
  static bool get canManageLoans => hasPermissionSync(AdminPermissionKeys.manageLoans);
  
  /// Check if admin can manage suggestions
  static bool get canManageSuggestions => hasPermissionSync(AdminPermissionKeys.manageSuggestions);
  
  /// Clear permissions (on logout)
  static Future<void> clearPermissions() async {
    await _storage.delete(key: _permissionsKey);
    _cachedPermissions = [];
    _isLoaded = false;
  }
  
  /// Refresh permissions from storage
  static Future<void> refresh() async {
    _isLoaded = false;
    await loadPermissions();
  }
  
  /// Build menu items - show ALL screens regardless of permissions
  /// Admin can view all screens, but action buttons are permission-based
  static List<PopupMenuItem<String>> buildMenuItems() {
    // Always show all menu items - permission only affects action buttons
    return const [
      PopupMenuItem(value: '/admin/books', child: Text('Books')),
      PopupMenuItem(value: '/admin/students', child: Text('Students')),
      PopupMenuItem(value: '/admin/loans', child: Text('Loans')),
      PopupMenuItem(value: '/admin/requests', child: Text('Requests')),
      PopupMenuItem(value: '/admin/suggested-books', child: Text('Suggested')),
      PopupMenuItem(value: '/admin/payments', child: Text('Payments')),
    ];
  }
}
