import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import 'book_screen.dart';
import 'request_screen.dart';
import 'student_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../utils/js_safe.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> stats = {
    'totalBooks': 0,
    'totalCopies': 0,
    'totalStudents': 0,
    'booksLoaned': 0,
    'booksReturned': 0,
    'overdueBooks': 0,
  };

  bool loading = false;
  final ApiService api = ApiService();

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    try {
      if (mounted) setState(() => loading = true);

      final data = await api.getAdminDashboard();

      if (!mounted) return;

      if (data['success'] == true && data['stats'] != null) {
        if (mounted) {
          setState(() {
            stats = sanitizeMap(Map.from(data['stats']));
          });
        }
      }
    } catch (e) {
      debugPrint('Fetch stats error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget buildStatCard(
    IconData icon,
    String title,
    String value,
    String subtitle,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    double iconSize = 24;
    double titleSize = 14;
    double valueSize = 18;
    double subtitleSize = 12;

    // shrink font sizes on very small screens
    if (screenWidth < 325) {
      iconSize = 18;
      titleSize = 12;
      valueSize = 14;
      subtitleSize = 10;
    } else if (screenWidth < 400) {
      iconSize = 20;
      titleSize = 13;
      valueSize = 16;
      subtitleSize = 11;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: iconSize, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: subtitleSize, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void navigateTo(String route) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'last_route', value: route);

    if (!mounted) return;

    switch (route) {
      case '/admin/books':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminBooksScreen()),
        );
        break;
      case '/admin/students':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminStudentsScreen()),
        );
        break;
      case '/admin/loans':
        Navigator.pushReplacementNamed(context, '/admin/loans');
        break;
      case '/admin/requests':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminRequestsScreen()),
        );
        break;
      case '/admin/suggested-books':
        Navigator.pushReplacementNamed(context, '/admin/suggested-books');
        break;
      case '/auth/logout':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;
    if (screenWidth < 525) {
      crossAxisCount = 1; // small mobile
    } else {
      crossAxisCount = 2; // tablets / medium screens
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Dashboard',
            onPressed: () => navigateTo('/admin/dashboard'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (String value) {
              if (value.isNotEmpty) navigateTo(value);
            },
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem(value: '/admin/books', child: Text('Books')),
              PopupMenuItem(value: '/admin/students', child: Text('Students')),
              PopupMenuItem(value: '/admin/loans', child: Text('Loans')),
              PopupMenuItem(value: '/admin/requests', child: Text('Requests')),
              PopupMenuItem(
                value: '/admin/suggested-books',
                child: Text('Suggested'),
              ),
              PopupMenuItem(value: '/auth/logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100), // <-- max width
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      const Text(
                        'Overview',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
  crossAxisCount: crossAxisCount,
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
  childAspectRatio: (() {
    final screenHeight = MediaQuery.of(context).size.height;

    if (screenHeight < 325) {
      return 1.2; // very short screens
    } else if (screenHeight > 900) {
      return 2.5; // tall screens — normal ratio
    } else {
      return 2.0; // medium-height screens — slightly smaller height
    }
  })(),
  children: [
    buildStatCard(Icons.menu_book, 'Total Books', safeString(stats['totalBooks']), 'Books in library'),
    buildStatCard(Icons.library_books, 'Total Copies', safeString(stats['totalCopies']), 'All copies'),
    buildStatCard(Icons.people, 'Total Students', safeString(stats['totalStudents']), 'Registered users'),
    buildStatCard(Icons.bookmark, 'Books Loaned', safeString(stats['booksLoaned']), 'Currently borrowed'),
    buildStatCard(Icons.check_circle, 'Books Returned', safeString(stats['booksReturned']), 'Successfully returned'),
    buildStatCard(Icons.warning_amber, 'Overdue Books', safeString(stats['overdueBooks']), 'Late returns'),
  ],
),

                      const SizedBox(height: 24),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              '© ${DateTime.now().year} Online Library Management System',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Contact: library@university.edu | +880-123-456789',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
