import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/admin_permissions.dart';

class ApiService {
  // Backend base URL - localhost for web, IP for phone
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';  // Web/Chrome
    } else {
      return 'http://192.168.0.101:3000';  // Phone/Mobile
    }
  }

  // Secure storage for JWT token and last route
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // ------------------- Helper -------------------
  Future<Map<String, String>> _getHeaders({bool withAuth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (withAuth) {
      final token = await storage.read(key: 'jwt_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ------------------- Auth -------------------
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String role,
    String? studentId,
    String? mobileNo,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'student_id': studentId,
        'mobile_no': mobileNo,
      }),
    );

    final data = jsonDecode(response.body);
    if (data['success'] == true && data['token'] != null) {
      await storage.write(key: 'jwt_token', value: data['token']);
    }
    return data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _getHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (data['success'] == true && data['token'] != null) {
      await storage.write(key: 'jwt_token', value: data['token']);
    }
    return data;
  }

  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'last_route');
    await AdminPermissionService.clearPermissions();
  }

  Future<bool> isLoggedIn() async {
    final token = await storage.read(key: 'jwt_token');
    return token != null;
  }

  // ------------------- Last Route -------------------
  Future<void> saveLastRoute(String route) async {
    await storage.write(key: 'last_route', value: route);
  }

  Future<String?> getLastRoute() async {
    return await storage.read(key: 'last_route');
  }

  // ------------------- Admin -------------------
  Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/dashboard'),
      headers: await _getHeaders(withAuth: true),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getAllBooks({String? search}) async {
    String url = '$baseUrl/admin/books';
    if (search != null) url += '?search=$search';
    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(withAuth: true),
    );
    return jsonDecode(response.body);
  }

  // Fetch suggested books for admin
  Future<Map<String, dynamic>> getSuggestedBooks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/suggested-books'),
      headers: await _getHeaders(withAuth: true),
    );
    return jsonDecode(response.body);
  }

  // Delete a suggested book by id (admin only)
  // Robust to endpoints that may return empty or non-JSON bodies (avoids FormatException)
  Future<Map<String, dynamic>> deleteSuggestedBook({required int id}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/suggested-books/$id'),
      headers: await _getHeaders(withAuth: true),
    );

    // Successful HTTP status
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // If body is empty or not JSON, return a generic success map
      if (response.body.trim().isEmpty) {
        return {'success': true, 'message': 'Deleted'};
      }
      try {
        return jsonDecode(response.body);
      } catch (e) {
        // Non-JSON but successful response
        return {'success': true, 'message': 'Deleted', 'raw': response.body};
      }
    }

    // Non-success status: try to parse JSON error, otherwise return a structured error
    try {
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Server error',
        'statusCode': response.statusCode,
        'body': response.body
      };
    }
  }

  Future<Map<String, dynamic>> addBook({
    required String title,
    required String author,
    required int totalCopies,
    required String genre,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/books/add'),
      headers: await _getHeaders(withAuth: true),
      body: jsonEncode({
        'title': title,
        'author': author,
        'total_copies': totalCopies,
        'genre': genre,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateBook({
    required int id,
    required String title,
    required String author,
    required int totalCopies,
    required String genre,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/books/update'),
      headers: await _getHeaders(withAuth: true),
      body: jsonEncode({
        'id': id,
        'title': title,
        'author': author,
        'total_copies': totalCopies,
        'genre': genre,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> deleteBook({required int id}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/books/delete'),
      headers: await _getHeaders(withAuth: true),
      body: jsonEncode({'id': id}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getAllStudents({String? search}) async {
    String url = '$baseUrl/admin/students';
    if (search != null) url += '?search=$search';
    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(withAuth: true),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getAllLoans({String? search}) async {
    String url = '$baseUrl/admin/loans';
    if (search != null) url += '?search=$search';
    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(withAuth: true),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> returnBook({
    required int loanId,
    required int bookId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/loans/return'),
      headers: await _getHeaders(withAuth: true),
      body: jsonEncode({'loan_id': loanId, 'book_id': bookId}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getAllRequests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/requests'),
      headers: await _getHeaders(withAuth: true),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> approveRequest({required int id}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/requests/$id/approve'),
      headers: await _getHeaders(withAuth: true),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> rejectRequest({required int id}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/requests/$id/reject'),
      headers: await _getHeaders(withAuth: true),
    );
    return jsonDecode(response.body);
  }

  // ------------------- Student -------------------
  Future<Map<String, dynamic>> getStudentDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/student/dashboard'),
      headers: await _getHeaders(withAuth: true),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getStudentBooks({String? search}) async {
    String url = '$baseUrl/student/books';
    if (search != null) url += '?search=$search';
    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(withAuth: true),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getMyBooks({String? search}) async {
    String url = '$baseUrl/student/mybooks';
    if (search != null) url += '?search=$search';
    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(withAuth: true),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> borrowBook({required int bookId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/student/borrow-request'),
      headers: await _getHeaders(withAuth: true),
      body: jsonEncode({'bookId': bookId}),
    );
    return jsonDecode(response.body);
  }

  // ------------------- Super Admin - Admin Management -------------------
  
  /// Get all admins (Super Admin only)
  /// Get all admins (Super Admin only)
  Future<Map<String, dynamic>> getAllAdmins({String? search}) async {
    String url = '$baseUrl/superadmin/admins';
    if (search != null && search.isNotEmpty) url += '?search=$search';
    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(withAuth: true),
    );
    return jsonDecode(response.body);
  }

  /// Get available admin permissions (Super Admin only)
  Future<Map<String, dynamic>> getAdminPermissions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/superadmin/permissions'),
      headers: await _getHeaders(withAuth: true),
    );
    return jsonDecode(response.body);
  }

  /// Get admin by ID (Super Admin only)
  Future<Map<String, dynamic>> getAdminById({required int id}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/superadmin/admins/$id'),
      headers: await _getHeaders(withAuth: true),
    );
    return jsonDecode(response.body);
  }

  /// Create new admin with permissions (Super Admin only)
  Future<Map<String, dynamic>> createAdmin({
    required String name,
    required String email,
    required String password,
    String? mobileNo,
    List<String>? permissions,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/superadmin/admins/add'),
      headers: await _getHeaders(withAuth: true),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'mobile_no': mobileNo,
        'permissions': permissions ?? [],
      }),
    );
    return jsonDecode(response.body);
  }

  /// Update admin details with permissions (Super Admin only)
  Future<Map<String, dynamic>> updateAdmin({
    required int id,
    required String name,
    required String email,
    String? mobileNo,
    List<String>? permissions,
  }) async {
    final Map<String, dynamic> body = {
      'name': name,
      'email': email,
      'mobile_no': mobileNo,
    };
    if (permissions != null) {
      body['permissions'] = permissions;
    }
    final response = await http.put(
      Uri.parse('$baseUrl/superadmin/admins/$id'),
      headers: await _getHeaders(withAuth: true),
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  /// Update admin permissions only (Super Admin only)
  Future<Map<String, dynamic>> updateAdminPermissions({
    required int id,
    required List<String> permissions,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/superadmin/admins/$id/permissions'),
      headers: await _getHeaders(withAuth: true),
      body: jsonEncode({'permissions': permissions}),
    );
    return jsonDecode(response.body);
  }

  /// Update admin password (Super Admin only)
  Future<Map<String, dynamic>> updateAdminPassword({
    required int id,
    required String password,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/superadmin/admins/$id/password'),
      headers: await _getHeaders(withAuth: true),
      body: jsonEncode({'password': password}),
    );
    return jsonDecode(response.body);
  }

  /// Delete admin (Super Admin only)
  Future<Map<String, dynamic>> deleteAdmin({required int id}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/superadmin/admins/$id'),
      headers: await _getHeaders(withAuth: true),
    );
    return jsonDecode(response.body);
  }

  /// Delete student (Admin or Super Admin)
  Future<Map<String, dynamic>> deleteStudent({required int id}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/students/$id'),
      headers: await _getHeaders(withAuth: true),
    );
    return jsonDecode(response.body);
  }

  // ------------------- Payments -------------------
  
  /// Make a payment for a loan penalty (Student)
  Future<Map<String, dynamic>> makePayment({
    required int loanId,
    required int amount,
    required String paymentMethod,
    String? reference,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/student/payments'),
      headers: await _getHeaders(withAuth: true),
      body: jsonEncode({
        'loan_id': loanId,
        'amount': amount,
        'payment_method': paymentMethod,
        'reference': reference,
      }),
    );
    return jsonDecode(response.body);
  }

  /// Get payment history for current student
  Future<Map<String, dynamic>> getPaymentHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/student/payments'),
      headers: await _getHeaders(withAuth: true),
    );
    return jsonDecode(response.body);
  }

  /// Get all payments (Admin)
  Future<Map<String, dynamic>> getAllPayments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/payments'),
      headers: await _getHeaders(withAuth: true),
    );
    return jsonDecode(response.body);
  }

  /// Update student profile
  Future<Map<String, dynamic>> updateStudentProfile({
    required String name,
    String? mobileNo,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/student/profile'),
      headers: await _getHeaders(withAuth: true),
      body: jsonEncode({
        'name': name,
        'mobile_no': mobileNo,
      }),
    );
    return jsonDecode(response.body);
  }

  /// Change student password
  Future<Map<String, dynamic>> changeStudentPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/student/change-password'),
      headers: await _getHeaders(withAuth: true),
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    return jsonDecode(response.body);
  }

  /// Change superadmin password
  Future<Map<String, dynamic>> changeSuperAdminPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/superadmin/change-password'),
      headers: await _getHeaders(withAuth: true),
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    return jsonDecode(response.body);
  }
}
