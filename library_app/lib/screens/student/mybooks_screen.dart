import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../utils/js_safe.dart';
import 'allbooks_screen.dart';
import 'dashboard_screen.dart';
import '../auth/login_screen.dart';

class StudentMyBooksScreen extends StatefulWidget {
  final Map? loans;
  const StudentMyBooksScreen({super.key, this.loans});

  @override
  State<StudentMyBooksScreen> createState() => _StudentMyBooksScreenState();
}

class _StudentMyBooksScreenState extends State<StudentMyBooksScreen> {
  final TextEditingController searchController = TextEditingController();
  final ApiService apiService = ApiService();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  List<Map<String, dynamic>> currentLoans = [];
  List<Map<String, dynamic>> pastLoans = [];
  int borrowed = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.loans != null) {
      currentLoans = List<Map<String, dynamic>>.from(widget.loans?['currentLoans'] ?? []);
      pastLoans = List<Map<String, dynamic>>.from(widget.loans?['pastLoans'] ?? []);
      borrowed = widget.loans?['borrowed'] ?? 0;
      isLoading = false;
    } else {
      fetchMyBooks();
    }
  }

  Future<void> fetchMyBooks({String search = ''}) async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final data = await apiService.getMyBooks(search: search);
      if (!mounted) return;
      setState(() {
        currentLoans = sanitizeListOfMaps(List.from(data['currentLoans'] ?? []));
        pastLoans = sanitizeListOfMaps(List.from(data['pastLoans'] ?? []));
        borrowed = data['borrowed'] ?? 0;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  int calculateDaysLeft(Object? returnDate) {
    final today = DateTime.now();
    final due = safeParseDate(returnDate);
    if (due == null) return 0; // unable to parse -> treat as 0 days left
    return due.difference(today).inDays;
  }

  Future<void> navigateTo(String route) async {
    if (!mounted) return;
    await storage.write(key: 'last_route', value: route);
    if (!mounted) return;

    switch (route) {
      case '/student/books':
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentAllBooksScreen()),
        );
        break;
      case '/student/mybooks':
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => StudentMyBooksScreen()),
        );
        break;
      case '/student/dashboard':
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
        );
        break;
      case '/auth/logout':
        if (!mounted) return;
        await apiService.logout();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final maxWidth = width > 1100 ? 1100.0 : width * 0.95;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('📖 My Borrowed Books'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Dashboard',
            onPressed: () {
              if (!mounted) return;
              navigateTo('/student/dashboard');
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) {
              if (!mounted) return;
              if (value.isNotEmpty) navigateTo(value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: '/student/books', child: Text('All Books')),
              PopupMenuItem(value: '/student/mybooks', child: Text('My Books')),
              PopupMenuItem(value: '/auth/logout', child: Text('Logout')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              if (!mounted) return;
              fetchMyBooks();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Search Bar
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                hintText: 'Search books by title, author...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onSubmitted: (_) {
                                if (!mounted) return;
                                fetchMyBooks(search: searchController.text);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (!mounted) return;
                              fetchMyBooks(search: searchController.text);
                            },
                            child: const Text('🔍 Search'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Currently Borrowed Books
                      Row(
                        children: [
                          const Text(
                            'Currently Borrowed',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          if (borrowed >= 3)
                            const Text(
                              '(Limit Reached)',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      currentLoans.isEmpty
                          ? const Text('No books currently borrowed.')
                          : Column(
                              children: currentLoans.map((loan) {
                                final daysLeft = calculateDaysLeft(loan['return_date']);
                                return Card(
                                  elevation: 3,
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    title: Text(
                                      safeString(loan['title']),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.black87),
                                    ),
                                    subtitle: Builder(builder: (_) {
                                      final issued = safeParseDate(loan['issued_at']);
                                      final ret = safeParseDate(loan['return_date']);
                                      final issuedText = issued != null
                                          ? issued.toLocal().toShortDateString()
                                          : safeString(loan['issued_at']);
                                      final returnText = ret != null
                                          ? ret.toLocal().toShortDateString()
                                          : safeString(loan['return_date']);
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Issued: $issuedText',
                                            style: const TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            'Return: $returnText',
                                            style: const TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(height: 4),
                                          daysLeft < 0
                                              ? const Text('Overdue',
                                                  style: TextStyle(
                                                      color: Colors.red,
                                                      fontWeight: FontWeight.bold))
                                              : Text('$daysLeft days left',
                                                  style: const TextStyle(
                                                      color: Colors.green,
                                                      fontWeight: FontWeight.w600)),
                                        ],
                                      );
                                    }),
                                    trailing: loan['status'] == 'overdue'
                                        ? const Text('Overdue',
                                            style: TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold))
                                        : Text(
                                            safeString(loan['status']),
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                  ),
                                );
                              }).toList(),
                            ),
                      const SizedBox(height: 30),
                      // Returned Books
                      const Text('Returned Books',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      pastLoans.isEmpty
                          ? const Text('No books returned yet.')
                          : Column(
                              children: pastLoans.map((loan) {
                                return Card(
                                  elevation: 3,
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    leading: const Icon(Icons.check_circle, color: Colors.green),
                                    title: Text(
                                      safeString(loan['title']),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87),
                                    ),
                                    subtitle: Builder(builder: (_) {
                                      final issued = safeParseDate(loan['issued_at']);
                                      final ret = safeParseDate(loan['return_date']);
                                      final returned = safeParseDate(loan['returned_at']);
                                      final issuedText = issued != null
                                          ? issued.toLocal().toShortDateString()
                                          : safeString(loan['issued_at']);
                                      final returnText = ret != null
                                          ? ret.toLocal().toShortDateString()
                                          : safeString(loan['return_date']);
                                      final returnedText = returned != null
                                          ? returned.toLocal().toShortDateString()
                                          : safeString(loan['returned_at']);
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Issued: $issuedText',
                                            style: const TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            'Return: $returnText',
                                            style: const TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            'Returned: $returnedText',
                                            style: const TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      );
                                    }),
                                    trailing: Text(
                                      loan['status'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

// Extension for consistent date formatting
extension DateHelpers on DateTime {
  String toShortDateString() {
    return "${day.toString().padLeft(2, '0')}/"
        "${month.toString().padLeft(2, '0')}/"
        "$year";
  }
}
