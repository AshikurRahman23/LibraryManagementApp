import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../utils/admin_permissions.dart';
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
  bool permissionsLoaded = false;
  final ApiService api = ApiService();

  @override
  void initState() {
    super.initState();
    _saveCurrentRoute();
    _loadPermissions();
    fetchStats();
  }

  Future<void> _loadPermissions() async {
    await AdminPermissionService.loadPermissions();
    if (mounted) {
      setState(() => permissionsLoaded = true);
    }
  }

  Future<void> _saveCurrentRoute() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'last_route', value: '/admin/dashboard');
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
    Color accentColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withOpacity(0.15),
                    accentColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
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
      case '/admin/payments':
        Navigator.pushReplacementNamed(context, '/admin/payments');
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(themeController.themeModeIcon),
            tooltip: 'Theme: ${themeController.themeModeLabel}',
            onPressed: () => themeController.cycleThemeMode(),
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Dashboard',
            onPressed: () => navigateTo('/admin/dashboard'),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () {
              if (!mounted) return;
              navigateTo('/auth/logout');
            },
            icon: const Icon(Icons.logout),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (String value) {
              if (value.isNotEmpty) navigateTo(value);
            },
            itemBuilder: (BuildContext context) => AdminPermissionService.buildMenuItems(),
          ),
        ],
      ),
      body: loading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Breakpoints.getMaxContentWidth(context),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Overview',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth = constraints.maxWidth < 400
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 12) / 2;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: cardWidth,
                                child: buildStatCard(Icons.menu_book_outlined, 'Total Books', safeString(stats['totalBooks']), 'Books in library', Colors.blue),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: buildStatCard(Icons.library_books_outlined, 'Total Copies', safeString(stats['totalCopies']), 'All copies', Colors.indigo),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: buildStatCard(Icons.people_outline, 'Total Students', safeString(stats['totalStudents']), 'Registered users', Colors.teal),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: buildStatCard(Icons.bookmark_outline, 'Books Loaned', safeString(stats['booksLoaned']), 'Currently borrowed', Colors.orange),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: buildStatCard(Icons.check_circle_outline, 'Books Returned', safeString(stats['booksReturned']), 'Successfully returned', Colors.green),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: buildStatCard(Icons.warning_amber_outlined, 'Overdue Books', safeString(stats['overdueBooks']), 'Late returns', Colors.red),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              '© ${DateTime.now().year} Online Library Management System',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Contact: library@university.edu | +880-123-456789',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
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
