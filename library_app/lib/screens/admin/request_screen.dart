import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/js_safe.dart';
import 'book_screen.dart';
import 'dashboard_screen.dart';
import 'student_screen.dart';
import '../../screens/auth/login_screen.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
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
    await storage.write(key: 'last_route', value: '/admin/requests');
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
      case '/admin/books':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminBooksScreen()));
        break;
      case '/admin/students':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminStudentsScreen()));
        break;
      case '/admin/loans':
        Navigator.pushReplacementNamed(context, '/admin/loans');
        break;
      case '/admin/dashboard':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrow Requests'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
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
            onSelected: navigateTo,
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
            onPressed: fetchRequests,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.getMaxContentWidth(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Expanded(
                child: loading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      )
                    : requests.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 64,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No pending requests at the moment',
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
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
                                              style: textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '$studentName | ID: $studentId',
                                              style: textTheme.bodyMedium?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                            Text(
                                              'Requested: $requestedAt',
                                              style: textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            if (status == 'pending')
                                              Wrap(
                                                alignment: WrapAlignment.end,
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  OutlinedButton.icon(
                                                    onPressed: () => rejectRequest(r['id']),
                                                    icon: Icon(Icons.close, size: 18, color: colorScheme.error),
                                                    label: Text('Reject', style: TextStyle(color: colorScheme.error)),
                                                    style: OutlinedButton.styleFrom(
                                                      side: BorderSide(color: colorScheme.error),
                                                    ),
                                                  ),
                                                  FilledButton.icon(
                                                    onPressed: () => approveRequest(r['id']),
                                                    icon: const Icon(Icons.check, size: 18),
                                                    label: const Text('Approve'),
                                                  ),
                                                ],
                                              )
                                            else
                                              Align(
                                                alignment: Alignment.centerRight,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: status == 'approved'
                                                        ? Colors.green.withOpacity(0.12)
                                                        : colorScheme.errorContainer,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    status.toUpperCase(),
                                                    style: textTheme.labelMedium?.copyWith(
                                                      color: status == 'approved'
                                                          ? Colors.green.shade700
                                                          : colorScheme.error,
                                                      fontWeight: FontWeight.w600,
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
