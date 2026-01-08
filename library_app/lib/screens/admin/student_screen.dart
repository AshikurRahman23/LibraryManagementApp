import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../utils/js_safe.dart';
import 'dashboard_screen.dart';
import 'book_screen.dart';
import 'request_screen.dart';
import '../../screens/auth/login_screen.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final ApiService api = ApiService();
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> filteredStudents = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
    fetchStudents();
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredStudents = List.from(students);
      } else {
        filteredStudents = students.where((s) {
          return s['name'].toString().toLowerCase().contains(query) ||
              s['email'].toString().toLowerCase().contains(query) ||
              s['student_id'].toString().toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> fetchStudents([String? search]) async {
    try {
      if (mounted) setState(() => loading = true);
      final data = await api.getAllStudents(search: search);
      if (!mounted) return;

      if (data['success'] == true && data['students'] != null) {
        if (mounted) {
          setState(() {
            students = sanitizeListOfMaps(List.from(data['students'] ?? []));
            filteredStudents = List.from(students);
          });
          _onSearchChanged();
        }
      }
    } catch (e) {
      debugPrint('Fetch students error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void navigateTo(String route) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'last_route', value: route);
    if (!mounted) return;

    switch (route) {
      case '/admin/books':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminBooksScreen()));
        break;
      case '/admin/dashboard':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
        break;
      case '/admin/loans':
        Navigator.pushReplacementNamed(context, '/admin/loans');
        break;
      case '/admin/requests':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminRequestsScreen()));
        break;
      case '/admin/suggested-books':
        Navigator.pushReplacementNamed(context, '/admin/suggested-books');
        break;
      case '/admin/payments':
        Navigator.pushReplacementNamed(context, '/admin/payments');
        break;
      case '/auth/logout':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        break;
    }
  }

  void _showDeleteDialog(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text(
          'Are you sure you want to delete "${student['name']}"?\n\n'
          'Email: ${student['email']}\n'
          'Student ID: ${student['student_id']}\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteStudent(student);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStudent(Map<String, dynamic> student) async {
    try {
      setState(() => loading = true);
      final result = await api.deleteStudent(id: student['id']);
      
      if (!mounted) return;
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Student "${student['name']}" deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        fetchStudents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to delete student'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('👨‍🎓 Registered Students'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Dashboard',
            onPressed: () => navigateTo('/admin/dashboard'),
          ),
           IconButton(
            tooltip: 'logout',
            onPressed: () {
              if (!mounted) return;
              navigateTo('/auth/logout');
            },
             icon: const Icon(Icons.logout)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (String value) {
              if (value.isNotEmpty) navigateTo(value);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: '/admin/books', child: Text('Books')),
              PopupMenuItem(value: '/admin/students', child: Text('Students')),
              PopupMenuItem(value: '/admin/loans', child: Text('Loans')),
              PopupMenuItem(value: '/admin/requests', child: Text('Requests')),
              PopupMenuItem(value: '/admin/suggested-books', child: Text('Suggested')),
              PopupMenuItem(value: '/admin/payments', child: Text('Payments')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => fetchStudents(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search bar
                      TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search by name, email, or student ID',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Students list
                      loading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredStudents.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 40),
                                  child: Center(
                                    child: Text(
                                      'No students registered yet.',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.black54),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: filteredStudents.map((student) {
                                    final createdAt = safeParseDate(student['created_at']);
                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Name
                                            Text(
                                              student['name'] ?? 'N/A',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            // Email and ID
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'Email: ${safeString(student['email']).isEmpty ? 'N/A' : safeString(student['email'])}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  'ID: ${safeString(student['student_id']).isEmpty ? 'N/A' : safeString(student['student_id'])}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            // Mobile and Joined date
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'Mobile: ${safeString(student['mobile_no']).isEmpty ? 'N/A' : safeString(student['mobile_no'])}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  'Joined: ${createdAt != null ? createdAt.toShortDateString() : 'N/A'}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            // Delete button
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: ElevatedButton.icon(
                                                onPressed: () => _showDeleteDialog(student),
                                                icon: const Icon(Icons.delete, size: 18),
                                                label: const Text('Delete'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper extension to format DateTime
extension DateHelpers on DateTime {
  String toShortDateString() {
    return "${day.toString().padLeft(2,'0')}/${month.toString().padLeft(2,'0')}/${year}";
  }
}
