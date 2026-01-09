import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../utils/js_safe.dart';
import '../auth/login_screen.dart';

class SuperAdminPaymentHistoryScreen extends StatefulWidget {
  const SuperAdminPaymentHistoryScreen({super.key});

  @override
  State<SuperAdminPaymentHistoryScreen> createState() => _SuperAdminPaymentHistoryScreenState();
}

class _SuperAdminPaymentHistoryScreenState extends State<SuperAdminPaymentHistoryScreen> {
  final ApiService api = ApiService();
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> payments = [];
  List<Map<String, dynamic>> filteredPayments = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
    fetchPayments();
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
        filteredPayments = List.from(payments);
      } else {
        filteredPayments = payments.where((p) {
          return p['student_name'].toString().toLowerCase().contains(query) ||
              p['student_id'].toString().toLowerCase().contains(query) ||
              p['book_title'].toString().toLowerCase().contains(query) ||
              p['payment_method'].toString().toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> fetchPayments() async {
    try {
      if (mounted) setState(() => loading = true);
      final data = await api.getAllPayments();
      if (!mounted) return;

      if (data['success'] == true) {
        setState(() {
          payments = sanitizeListOfMaps(List.from(data['payments'] ?? []));
          filteredPayments = List.from(payments);
        });
        _onSearchChanged();
      }
    } catch (e) {
      debugPrint('Fetch payments error: $e');
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
        Navigator.pushReplacementNamed(context, '/superadmin/books');
        break;
      case '/superadmin/students':
        Navigator.pushReplacementNamed(context, '/superadmin/students');
        break;
      case '/superadmin/dashboard':
        Navigator.pushReplacementNamed(context, '/superadmin/dashboard');
        break;
      case '/superadmin/loans':
        Navigator.pushReplacementNamed(context, '/superadmin/loans');
        break;
      case '/superadmin/requests':
        Navigator.pushReplacementNamed(context, '/superadmin/requests');
        break;
      case '/superadmin/payments':
        Navigator.pushReplacementNamed(context, '/superadmin/payments');
        break;
      case '/superadmin/admins':
        Navigator.pushReplacementNamed(context, '/superadmin/admins');
        break;
      case '/superadmin/suggested-books':
        Navigator.pushReplacementNamed(context, '/superadmin/suggested-books');
        break;
      case '/auth/logout':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        break;
    }
  }

  IconData _getPaymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'bkash':
        return Icons.phone_android;
      case 'nagad':
        return Icons.smartphone;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  Color _getPaymentColor(String method) {
    switch (method.toLowerCase()) {
      case 'bkash':
        return const Color(0xFFE2136E);
      case 'nagad':
        return const Color(0xFFF6921E);
      case 'card':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('💳 Payment History'),
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
            onPressed: () => navigateTo('/auth/logout'),
            icon: const Icon(Icons.logout),
          ),
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
            onPressed: fetchPayments,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by roll/student ID, name, book, or method',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredPayments.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No payment records found.',
                                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredPayments.length,
                              itemBuilder: (_, index) {
                                final payment = filteredPayments[index];
                                final method = safeString(payment['payment_method']);
                                final paidAt = safeParseDate(payment['created_at']);
                                final roll = safeString(payment['student_id']);
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _getPaymentColor(method).withOpacity(0.2),
                                      child: Icon(
                                        _getPaymentIcon(method),
                                        color: _getPaymentColor(method),
                                      ),
                                    ),
                                    title: Text(
                                      safeString(payment['book_title']),
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Show Roll/Student ID from user record
                                        Text(
                                          'Roll: $roll',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'Name: ${safeString(payment['student_name'])}',
                                        ),
                                        Text('Method: ${method.toUpperCase()}'),
                                        Text(
                                          'Date: ${paidAt != null ? "${paidAt.day.toString().padLeft(2, '0')}/${paidAt.month.toString().padLeft(2, '0')}/${paidAt.year}" : 'N/A'}',
                                        ),
                                        Text(
                                          'Transaction: ${safeString(payment['transaction_id'])}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                    trailing: Text(
                                      '৳${payment['amount'] ?? 0}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                );
                              },
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
