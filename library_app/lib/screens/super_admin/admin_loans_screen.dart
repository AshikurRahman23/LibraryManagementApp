import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../utils/js_safe.dart';
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
    searchController.addListener(_onSearchChanged);
    fetchLoans();
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
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('📖 Manage Loans'),
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
            onPressed: () => fetchLoans(),
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
                    hintText: 'Search by book title, author, or student name',
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
                      : filteredLoans.isEmpty
                          ? const Center(
                              child: Text(
                                'No loan records available',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black54),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredLoans.length,
                              itemBuilder: (_, index) {
                                final loan = filteredLoans[index];
                                final isIssued = loan['status'] == 'issued';
                                final penalty = isIssued ? calculatePenalty(loan['return_date']?.toString()) : 0;

                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      safeString(loan['title']),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Borrowed by: ${safeString(loan['student_name'])} (ID: ${safeString(loan['student_id'])})',
                                        ),
                                        if (loan['return_date'] != null)
                                          Text(
                                            '📅 Due: ${safeString(loan['return_date']).split('T')[0]}',
                                          ),
                                        Text(
                                          'Status: ${safeString(loan['status']).toUpperCase()}',
                                          style: TextStyle(
                                            color: isIssued
                                                ? Colors.orange
                                                : Colors.green,
                                          ),
                                        ),
                                        if (isIssued && penalty > 0)
                                          Text(
                                            '💰 Penalty: ৳$penalty',
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: isIssued
                                        ? ElevatedButton(
                                            onPressed: () =>
                                                markReturned(
                                              loan['id'],
                                              loan['book_id'],
                                            ),
                                            child: const Text('Mark Returned'),
                                          )
                                        : const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
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
