import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
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
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    try {
      setState(() => loading = true);
      final data = await api.getAllRequests();
      if (data['success'] == true) {
        setState(() {
          requests = List<Map<String, dynamic>>.from(data['requests']);
        });
      }
    } catch (e) {
      debugPrint('Fetch requests error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> approveRequest(int id) async {
    final data = await api.approveRequest(id: id);
    if (data['success'] == true) {
      fetchRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request approved ✅')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Failed')),
      );
    }
  }

  Future<void> rejectRequest(int id) async {
    final data = await api.rejectRequest(id: id);
    if (data['success'] == true) {
      fetchRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected ❌')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Failed')),
      );
    }
  }

  void navigateTo(String route) async {
    final FlutterSecureStorage storage = const FlutterSecureStorage();
    await storage.write(key: 'last_route', value: route);

    switch (route) {
      case '/admin/books':
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => AdminBooksScreen()));
        break;
      case '/admin/students':
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => AdminStudentsScreen()));
        break;
      case '/admin/loans':
        Navigator.pushReplacementNamed(context, '/admin/loans');
        break;
      case '/admin/dashboard':
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => AdminDashboardScreen()));
        break;
      case '/auth/logout':
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => LoginScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('📌 Borrow Requests'),
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
              PopupMenuItem(value: '/auth/logout', child: Text('Logout')),
            ],
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
                            requests.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 40),
                                    child: Center(
                                      child: Text(
                                        'No pending requests at the moment 🎉',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.black54),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: requests.length,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final r = requests[index];
                                      final status =
                                          r['status'].toString().toLowerCase();
                                      return Card(
                                        elevation: 2,
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 6),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 8),
                                          title: Text(
                                            r['book_title'],
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          subtitle: Text(
                                            '${r['student_name']} | ID: ${r['student_id']}\nRequested at: ${DateTime.parse(r['requested_at']).toLocal().toString().split(' ')[0]}',
                                          ),
                                          isThreeLine: true,
                                          trailing: status == 'pending'
                                              ? Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          approveRequest(
                                                              r['id']),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.green,
                                                        padding:
                                                            const EdgeInsets
                                                                    .symmetric(
                                                                horizontal: 12,
                                                                vertical: 8),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            6)),
                                                      ),
                                                      child: const Text(
                                                        'Approve',
                                                        style: TextStyle(
                                                            fontSize: 12),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          rejectRequest(
                                                              r['id']),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                        padding:
                                                            const EdgeInsets
                                                                    .symmetric(
                                                                horizontal: 12,
                                                                vertical: 8),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            6)),
                                                      ),
                                                      child: const Text(
                                                        'Reject',
                                                        style: TextStyle(
                                                            fontSize: 12),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Text(
                                                  status.toUpperCase(),
                                                  style: TextStyle(
                                                    color: status == 'approved'
                                                        ? Colors.green
                                                        : Colors.red,
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
