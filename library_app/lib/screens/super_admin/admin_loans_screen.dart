import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../utils/js_safe.dart';
import '../../theme/app_theme.dart';
import '../../screens/auth/login_screen.dart';

class SuperAdminLoansScreen extends StatefulWidget {
  const SuperAdminLoansScreen({super.key});

  @override
  State<SuperAdminLoansScreen> createState() => _SuperAdminLoansScreenState();
}

class _SuperAdminLoansScreenState extends State<SuperAdminLoansScreen> {
  final ApiService api = ApiService();
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> loans = [];
  List<Map<String, dynamic>> filteredLoans = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _saveCurrentRoute();
    searchController.addListener(_onSearchChanged);
    fetchLoans();
  }

  Future<void> _saveCurrentRoute() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'last_route', value: '/superadmin/loans');
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
        filteredLoans = List.from(loans);
      } else {
        filteredLoans = loans.where((loan) {
          return loan['title'].toString().toLowerCase().contains(query) ||
              loan['author'].toString().toLowerCase().contains(query) ||
              loan['student_name'].toString().toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  int calculatePenalty(String? dueDate) {
    if (dueDate == null) return 0;
    final due = DateTime.tryParse(dueDate);
    if (due == null) return 0;
    final now = DateTime.now();
    if (now.isBefore(due)) return 0;
    final daysOverdue = now.difference(due).inDays;
    if (daysOverdue <= 0) return 0;
    final periods = ((daysOverdue - 1) ~/ 15) + 1;
    return periods * 10;
  }

  Future<void> fetchLoans([String? search]) async {
    try {
      if (mounted) setState(() => loading = true);
      final data = await api.getAllLoans();

      if (!mounted) return;

      if (data['success'] == true) {
        List<Map<String, dynamic>> allLoans =
            sanitizeListOfMaps(List.from(data['loans'] ?? []));

        if (mounted) {
          setState(() {
            loans = allLoans;
            filteredLoans = List.from(allLoans);
          });
          _onSearchChanged();
        }
      }
    } catch (e) {
      debugPrint('Fetch loans error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> markReturned(int loanId, int bookId) async {
    final data = await api.returnBook(loanId: loanId, bookId: bookId);

    if (!mounted) return;

    if (data['success'] == true) {
      fetchLoans();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book marked as returned')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(safeString(data['message']).isEmpty
              ? 'Operation failed'
              : safeString(data['message'])),
        ),
      );
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

      case '/superadmin/requests':
        Navigator.pushReplacementNamed(context, '/superadmin/requests');
        break;

      case '/superadmin/suggested-books':
        Navigator.pushReplacementNamed(context, '/superadmin/suggested-books');
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
    final maxWidth = Breakpoints.getMaxContentWidth(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Loans'),
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
            onPressed: () => fetchLoans(),
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
                    hintText: 'Search by book title, author, or student name',
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
                      : filteredLoans.isEmpty
                          ? Card(
                              elevation: 0,
                              color: colorScheme.surfaceContainerLow,
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.library_books_outlined, size: 48, color: colorScheme.onSurfaceVariant),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No loan records available',
                                      style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredLoans.length,
                              itemBuilder: (_, index) {
                                final loan = filteredLoans[index];
                                final isIssued = loan['status'] == 'issued';
                                final calculatedPenalty = isIssued ? calculatePenalty(loan['return_date']?.toString()) : 0;
                                final totalPaid = int.tryParse(loan['total_paid']?.toString() ?? '0') ?? 0;
                                final remainingPenalty = (calculatedPenalty - totalPaid).clamp(0, calculatedPenalty);
                                final isPenaltyFullyPaid = calculatedPenalty > 0 && remainingPenalty == 0;

                                return Card(
                                  elevation: 0,
                                  color: colorScheme.surfaceContainerLow,
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    title: Text(
                                      safeString(loan['title']),
                                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.person_outline, size: 16, color: colorScheme.onSurfaceVariant),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                '${safeString(loan['student_name'])} (ID: ${safeString(loan['student_id'])})',
                                                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (loan['return_date'] != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.event_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Due: ${safeString(loan['return_date']).split('T')[0]}',
                                                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isIssued ? colorScheme.tertiaryContainer : colorScheme.primaryContainer,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            safeString(loan['status']).toUpperCase(),
                                            style: textTheme.labelMedium?.copyWith(
                                              color: isIssued ? colorScheme.onTertiaryContainer : colorScheme.onPrimaryContainer,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (isIssued && calculatedPenalty > 0) ...[
                                          const SizedBox(height: 8),
                                          if (isPenaltyFullyPaid)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Paid: ৳$totalPaid',
                                                    style: textTheme.labelMedium?.copyWith(
                                                      color: Colors.green.shade700,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          else
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.errorContainer,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'Due: ৳$remainingPenalty',
                                                    style: textTheme.labelMedium?.copyWith(
                                                      color: colorScheme.onErrorContainer,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                if (totalPaid > 0)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      'Paid: ৳$totalPaid',
                                                      style: textTheme.labelMedium?.copyWith(
                                                        color: Colors.green.shade700,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                        ],
                                      ],
                                    ),
                                    trailing: isIssued
                                        ? FilledButton(
                                            onPressed: () =>
                                                markReturned(
                                              loan['id'],
                                              loan['book_id'],
                                            ),
                                            child: const Text('Mark Returned'),
                                          )
                                        : Icon(
                                            Icons.check_circle,
                                            color: colorScheme.primary,
                                            size: 32,
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
