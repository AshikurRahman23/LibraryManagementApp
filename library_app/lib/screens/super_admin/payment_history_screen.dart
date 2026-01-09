import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../utils/js_safe.dart';
import '../../theme/app_theme.dart';
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
    _saveCurrentRoute();
    searchController.addListener(_onSearchChanged);
    fetchPayments();
  }

  Future<void> _saveCurrentRoute() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'last_route', value: '/superadmin/payments');
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
            onPressed: () => navigateTo('/superadmin/dashboard'),
          ),
          IconButton(
            tooltip: 'Logout',
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
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by roll/student ID, name, book, or method',
                    prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: loading
                      ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                      : filteredPayments.isEmpty
                          ? Card(
                              elevation: 0,
                              color: colorScheme.surfaceContainerLow,
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.receipt_long_outlined, size: 64, color: colorScheme.onSurfaceVariant),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No payment records found.',
                                      style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
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
                                  elevation: 0,
                                  color: colorScheme.surfaceContainerLow,
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: Container(
                                      width: 48,
                                      height: 48,
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
                                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.badge_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                'Roll: $roll',
                                                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.person_outline, size: 16, color: colorScheme.onSurfaceVariant),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                safeString(payment['student_name']),
                                                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: colorScheme.secondaryContainer,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                method.toUpperCase(),
                                                style: textTheme.labelMedium?.copyWith(
                                                  color: colorScheme.onSecondaryContainer,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: colorScheme.tertiaryContainer,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                paidAt != null
                                                    ? "${paidAt.day.toString().padLeft(2, '0')}/${paidAt.month.toString().padLeft(2, '0')}/${paidAt.year}"
                                                    : 'N/A',
                                                style: textTheme.labelMedium?.copyWith(
                                                  color: colorScheme.onTertiaryContainer,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
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
