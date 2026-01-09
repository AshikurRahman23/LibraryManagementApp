import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/js_safe.dart';
import '../../screens/auth/login_screen.dart';

class AdminLoansScreen extends StatefulWidget {
  const AdminLoansScreen({super.key});

  @override
  State<AdminLoansScreen> createState() => _AdminLoansScreenState();
}

class _AdminLoansScreenState extends State<AdminLoansScreen> {
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
    await storage.write(key: 'last_route', value: '/admin/loans');
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
      case '/admin/books':
        Navigator.pushReplacementNamed(context, '/admin/books');
        break;

      case '/admin/students':
        Navigator.pushReplacementNamed(context, '/admin/students');
        break;

      case '/admin/dashboard':
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
        break;

      case '/admin/requests':
        Navigator.pushReplacementNamed(context, '/admin/requests');
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Management'),
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
            onPressed: () => fetchLoans(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.getMaxContentWidth(context),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by book title, author, or student name',
                    prefixIcon: Icon(
                      Icons.search,
                      color: colorScheme.onSurfaceVariant,
                    ),
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
                      ? Center(
                          child: CircularProgressIndicator(
                            color: colorScheme.primary,
                          ),
                        )
                      : filteredLoans.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.library_books_outlined,
                                    size: 64,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No loan records available',
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          safeString(loan['title']),
                                          style: textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Borrowed by: ${safeString(loan['student_name'])} (ID: ${safeString(loan['student_id'])})',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        if (loan['return_date'] != null)
                                          Text(
                                            'Due: ${safeString(loan['return_date']).split('T')[0]}',
                                            style: textTheme.bodyMedium?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isIssued
                                                    ? Colors.orange.withOpacity(0.12)
                                                    : Colors.green.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                safeString(loan['status']).toUpperCase(),
                                                style: textTheme.labelMedium?.copyWith(
                                                  color: isIssued ? Colors.orange.shade700 : Colors.green.shade700,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            if (isIssued && calculatedPenalty > 0) ...[
                                              if (isPenaltyFullyPaid)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(8),
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
                                              else ...[
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.errorContainer,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    'Due: ৳$remainingPenalty',
                                                    style: textTheme.labelMedium?.copyWith(
                                                      color: colorScheme.error,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                if (totalPaid > 0)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(8),
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
                                            ],
                                            if (isIssued)
                                              FilledButton(
                                                onPressed: () => markReturned(
                                                  loan['id'],
                                                  loan['book_id'],
                                                ),
                                                child: const Text('Mark Returned'),
                                              )
                                            else
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.green.shade600,
                                              ),
                                          ],
                                        ),
                                      ],
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
