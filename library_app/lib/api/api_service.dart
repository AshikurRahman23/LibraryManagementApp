import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Backend base URL
  static const String baseUrl = 'http://localhost:3000';

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
}
