import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../utils/js_safe.dart';
import '../../theme/app_theme.dart';
import 'allbooks_screen.dart';
import 'mybooks_screen.dart';
import 'dashboard_screen.dart';
import '../auth/login_screen.dart';

class StudentPaymentHistoryScreen extends StatefulWidget {
  const StudentPaymentHistoryScreen({super.key});

  @override
  State<StudentPaymentHistoryScreen> createState() => _StudentPaymentHistoryScreenState();
}

class _StudentPaymentHistoryScreenState extends State<StudentPaymentHistoryScreen> {
  final ApiService apiService = ApiService();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  List<Map<String, dynamic>> payments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _saveCurrentRoute();
    fetchPaymentHistory();
  }

  Future<void> _saveCurrentRoute() async {
    await storage.write(key: 'last_route', value: '/student/payments');
  }

  Future<void> fetchPaymentHistory() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final data = await apiService.getPaymentHistory();
      if (!mounted) return;
      setState(() {
        payments = sanitizeListOfMaps(List.from(data['payments'] ?? []));
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> navigateTo(String route) async {
    if (!mounted) return;
    await storage.write(key: 'last_route', value: route);
    if (!mounted) return;

    switch (route) {
      case '/student/books':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentAllBooksScreen()),
        );
        break;
      case '/student/mybooks':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentMyBooksScreen()),
        );
        break;
      case '/student/dashboard':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
        );
        break;
      case '/student/payments':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentPaymentHistoryScreen()),
        );
        break;
      case '/auth/logout':
        await apiService.logout();
        if (!mounted) return;
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxWidth = Breakpoints.getMaxContentWidth(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Dashboard',
            onPressed: () => navigateTo('/student/dashboard'),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => navigateTo('/auth/logout'),
            icon: const Icon(Icons.logout),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: navigateTo,
            itemBuilder: (context) => const [
              PopupMenuItem(value: '/student/books', child: Text('All Books')),
              PopupMenuItem(value: '/student/mybooks', child: Text('My Books')),
              PopupMenuItem(value: '/student/payments', child: Text('Payments')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: fetchPaymentHistory,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Your Payment History',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: payments.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.receipt_long_outlined, size: 80, color: colorScheme.onSurfaceVariant),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No payment history yet.',
                                      style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: payments.length,
                                itemBuilder: (_, index) {
                                  final payment = payments[index];
                                  final method = safeString(payment['payment_method']);
                                  final paidAt = safeParseDate(payment['created_at']);
                                  return Card(
                                    elevation: 0,
                                    color: colorScheme.surfaceContainerLow,
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      leading: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: _getPaymentColor(method).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _getPaymentIcon(method),
                                          color: _getPaymentColor(method),
                                        ),
                                      ),
                                      title: Text(
                                        safeString(payment['book_title']),
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            'Method: ${method.toUpperCase()}',
                                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                                          ),
                                          Text(
                                            'Date: ${paidAt != null ? "${paidAt.day.toString().padLeft(2, '0')}/${paidAt.month.toString().padLeft(2, '0')}/${paidAt.year}" : 'N/A'}',
                                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                                          ),
                                          Text(
                                            'Transaction: ${safeString(payment['transaction_id'])}',
                                            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                          ),
                                        ],
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '৳${payment['amount'] ?? 0}',
                                          style: textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onPrimaryContainer,
                                          ),
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

// Use DateHelpers from mybooks_screen.dart to avoid duplicate extension
