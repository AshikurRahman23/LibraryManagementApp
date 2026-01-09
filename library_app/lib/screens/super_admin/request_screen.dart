import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../utils/js_safe.dart';
import '../../theme/app_theme.dart';
import 'book_screen.dart' as super_admin_book;
import 'student_screen.dart' as super_admin_student;
import '../../screens/auth/login_screen.dart';

typedef SuperAdminBooksScreen = super_admin_book.SuperAdminBooksScreen;
typedef SuperAdminStudentsScreen = super_admin_student.SuperAdminStudentsScreen;

class SuperAdminRequestsScreen extends StatefulWidget {
  const SuperAdminRequestsScreen({super.key});

  @override
  State<SuperAdminRequestsScreen> createState() => _SuperAdminRequestsScreenState();
}

class _SuperAdminRequestsScreenState extends State<SuperAdminRequestsScreen> {
  final ApiService api = ApiService();
  List<Map<String, dynamic>> requests = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _saveCurrentRoute();
    fetchRequests();
  }

  Future<void> _saveCurrentRoute() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'last_route', value: '/superadmin/requests');
  }

  Future<void> fetchRequests() async {
    try {
      if (mounted) setState(() => loading = true);
      final data = await api.getAllRequests();
      if (!mounted) return;

      if (data['success'] == true) {
        if (mounted) {
          setState(() {
            requests = sanitizeListOfMaps(List.from(data['requests'] ?? []));
          });
        }
      }
    } catch (e) {
      debugPrint('Fetch requests error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> approveRequest(int id) async {
    final data = await api.approveRequest(id: id);
    if (!mounted) return;

    if (data['success'] == true) {
      await fetchRequests();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request approved ✅')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(safeString(data['message']).isEmpty ? 'Failed' : safeString(data['message']))),
      );
    }
  }

  Future<void> rejectRequest(int id) async {
    final data = await api.rejectRequest(id: id);
    if (!mounted) return;

    if (data['success'] == true) {
      await fetchRequests();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected ❌')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(safeString(data['message']).isEmpty ? 'Failed' : safeString(data['message']))),
      );
    }
  }

  void navigateTo(String route) async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    await storage.write(key: 'last_route', value: route);
    if (!mounted) return;

    switch (route) {
      case '/superadmin/books':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SuperAdminBooksScreen()));
        break;
      case '/superadmin/students':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SuperAdminStudentsScreen()));
        break;
      case '/superadmin/loans':
        Navigator.pushReplacementNamed(context, '/superadmin/loans');
        break;
      case '/superadmin/dashboard':
        Navigator.pushReplacementNamed(context, '/superadmin/dashboard');
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxWidth = Breakpoints.getMaxContentWidth(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Requests'),
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
            onSelected: navigateTo,
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
            onPressed: fetchRequests,
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
                child: loading
                    ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                    : requests.isEmpty
                        ? Center(
                            child: Card(
                              elevation: 0,
                              color: colorScheme.surfaceContainerLow,
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_outline, size: 64, color: colorScheme.primary),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No pending requests at the moment',
                                      style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pending Borrow Requests',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListView.builder(
                                  itemCount: requests.length,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final r = requests[index];
                                    final status = r['status'].toString().toLowerCase();
                                    final studentName = safeString(r['student_name']);
                                    final studentId = safeString(r['student_id']);
                                    final requestedAt = safeParseDate(r['requested_at'])?.toLocal().toString().split(' ')[0] ?? safeString(r['requested_at']);

                                    return Card(
                                      elevation: 0,
                                      color: colorScheme.surfaceContainerLow,
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              safeString(r['book_title']),
                                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.person_outline, size: 16, color: colorScheme.onSurfaceVariant),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    studentName,
                                                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.primaryContainer,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text('ID: $studentId', style: textTheme.labelSmall?.copyWith(color: colorScheme.onPrimaryContainer)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.calendar_today_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'Requested: $requestedAt',
                                                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            if (status == 'pending')
                                              Wrap(
                                                alignment: WrapAlignment.end,
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  OutlinedButton(
                                                    onPressed: () => rejectRequest(r['id']),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: colorScheme.error,
                                                      side: BorderSide(color: colorScheme.error),
                                                    ),
                                                    child: const Text('Reject'),
                                                  ),
                                                  FilledButton(
                                                    onPressed: () => approveRequest(r['id']),
                                                    child: const Text('Approve'),
                                                  ),
                                                ],
                                              )
                                            else
                                              Align(
                                                alignment: Alignment.centerRight,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: status == 'approved' ? colorScheme.primaryContainer : colorScheme.errorContainer,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    status.toUpperCase(),
                                                    style: textTheme.labelMedium?.copyWith(
                                                      color: status == 'approved' ? colorScheme.onPrimaryContainer : colorScheme.onErrorContainer,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
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
