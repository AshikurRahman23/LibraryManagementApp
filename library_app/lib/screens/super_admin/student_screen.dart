import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../utils/js_safe.dart';
import '../../theme/app_theme.dart';
import 'book_screen.dart' as super_admin_book;
import 'request_screen.dart' as super_admin_request;
import '../../screens/auth/login_screen.dart';

typedef SuperAdminBooksScreen = super_admin_book.SuperAdminBooksScreen;
typedef SuperAdminRequestsScreen = super_admin_request.SuperAdminRequestsScreen;

class SuperAdminStudentsScreen extends StatefulWidget {
  const SuperAdminStudentsScreen({super.key});

  @override
  State<SuperAdminStudentsScreen> createState() => _SuperAdminStudentsScreenState();
}

class _SuperAdminStudentsScreenState extends State<SuperAdminStudentsScreen> {
  final ApiService api = ApiService();
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> filteredStudents = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _saveCurrentRoute();
    searchController.addListener(_onSearchChanged);
    fetchStudents();
  }

  Future<void> _saveCurrentRoute() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'last_route', value: '/superadmin/students');
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
      case '/superadmin/books':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SuperAdminBooksScreen()));
        break;
      case '/superadmin/dashboard':
        Navigator.pushReplacementNamed(context, '/superadmin/dashboard');
        break;
      case '/superadmin/loans':
        Navigator.pushReplacementNamed(context, '/superadmin/loans');
        break;
      case '/superadmin/requests':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SuperAdminRequestsScreen()));
        break;
      case '/superadmin/suggested-books':
        Navigator.pushReplacementNamed(context, '/superadmin/suggested-books');
        break;
      case '/superadmin/admins':
        Navigator.pushReplacementNamed(context, '/superadmin/admins');
        break;
      case '/superadmin/payments':
        Navigator.pushReplacementNamed(context, '/superadmin/payments');
        break;
      case '/auth/logout':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        break;
    }
  }

  void _showDeleteDialog(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        final textTheme = Theme.of(ctx).textTheme;
        
        return AlertDialog(
          title: Text('Delete Student', style: textTheme.titleLarge),
          content: Text(
            'Are you sure you want to delete "${student['name']}"?\n\n'
            'Email: ${student['email']}\n'
            'Student ID: ${student['student_id']}\n\n'
            'This action cannot be undone.',
            style: textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteStudent(student);
              },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxWidth = Breakpoints.getMaxContentWidth(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Dashboard',
            onPressed: () => navigateTo('/superadmin/dashboard'),
          ),
           IconButton(
            tooltip: 'Logout',
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
              PopupMenuItem(value: '/superadmin/books', child: Text('Books')),
              PopupMenuItem(value: '/superadmin/students', child: Text('Students')),
              PopupMenuItem(value: '/superadmin/loans', child: Text('Loans')),
              PopupMenuItem(value: '/superadmin/requests', child: Text('Requests')),
              PopupMenuItem(value: '/superadmin/suggested-books', child: Text('Suggested')),
              PopupMenuItem(value: '/superadmin/admins', child: Text('Admins')),
              PopupMenuItem(value: '/superadmin/payments', child: Text('Payments')),
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
          constraints: BoxConstraints(maxWidth: maxWidth),
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
                        decoration: InputDecoration(
                          hintText: 'Search by name, email, or student ID',
                          prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Students list
                      loading
                          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                          : filteredStudents.isEmpty
                              ? Card(
                                  elevation: 0,
                                  color: colorScheme.surfaceContainerLow,
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(Icons.people_outline, size: 48, color: colorScheme.onSurfaceVariant),
                                          const SizedBox(height: 12),
                                          Text(
                                            'No students registered yet.',
                                            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: filteredStudents.map((student) {
                                    final createdAt = safeParseDate(student['created_at']);
                                    return Card(
                                      elevation: 0,
                                      color: colorScheme.surfaceContainerLow,
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Name
                                            Text(
                                              student['name'] ?? 'N/A',
                                              style: textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            // Email and ID
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.email_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                                                      const SizedBox(width: 4),
                                                      Flexible(
                                                        child: Text(
                                                          safeString(student['email']).isEmpty ? 'N/A' : safeString(student['email']),
                                                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.primaryContainer,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    'ID: ${safeString(student['student_id']).isEmpty ? 'N/A' : safeString(student['student_id'])}',
                                                    style: textTheme.labelMedium?.copyWith(
                                                      color: colorScheme.onPrimaryContainer,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            // Mobile and Joined date
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.phone_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                                                      const SizedBox(width: 4),
                                                      Flexible(
                                                        child: Text(
                                                          safeString(student['mobile_no']).isEmpty ? 'N/A' : safeString(student['mobile_no']),
                                                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Flexible(
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.calendar_today_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                                                      const SizedBox(width: 4),
                                                      Flexible(
                                                        child: Text(
                                                          'Joined: ${createdAt != null ? createdAt.toShortDateString() : 'N/A'}',
                                                          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            // Delete button
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: FilledButton.tonalIcon(
                                                onPressed: () => _showDeleteDialog(student),
                                                icon: const Icon(Icons.delete_outline, size: 18),
                                                label: const Text('Delete'),
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: colorScheme.errorContainer,
                                                  foregroundColor: colorScheme.onErrorContainer,
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
