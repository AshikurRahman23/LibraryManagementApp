import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../utils/js_safe.dart';
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
    fetchRequests();
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
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('📌 Manage Requests'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Dashboard',
            onPressed: () => navigateTo('/superadmin/dashboard'),
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
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : requests.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Center(
                              child: Text(
                                'No pending requests at the moment 🎉',
                                style: TextStyle(fontSize: 16, color: Colors.black54),
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
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
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
                                      elevation: 2,
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        title: Text(
                                          safeString(r['book_title']),
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                        subtitle: Text('$studentName | ID: $studentId\nRequested at: $requestedAt'),
                                        isThreeLine: true,
                                        trailing: status == 'pending'
                                            ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ElevatedButton(
                                                    onPressed: () => approveRequest(r['id']),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.green,
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                    ),
                                                    child: const Text('Approve', style: TextStyle(fontSize: 12)),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  ElevatedButton(
                                                    onPressed: () => rejectRequest(r['id']),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.red,
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                    ),
                                                    child: const Text('Reject', style: TextStyle(fontSize: 12)),
                                                  ),
                                                ],
                                              )
                                            : Text(
                                                status.toUpperCase(),
                                                style: TextStyle(
                                                  color: status == 'approved' ? Colors.green : Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
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
