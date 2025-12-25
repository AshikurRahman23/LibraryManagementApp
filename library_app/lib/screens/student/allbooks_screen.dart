import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../utils/js_safe.dart';
import 'mybooks_screen.dart';
import 'dashboard_screen.dart';
import '../auth/login_screen.dart';

class StudentAllBooksScreen extends StatefulWidget {
  final String searchQuery;
  const StudentAllBooksScreen({super.key, this.searchQuery = ''});

  @override
  State<StudentAllBooksScreen> createState() => _StudentAllBooksScreenState();
}

class _StudentAllBooksScreenState extends State<StudentAllBooksScreen> {
  final TextEditingController searchController = TextEditingController();
  final ApiService apiService = ApiService();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  List<Map<String, dynamic>> books = [];
  int borrowed = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    searchController.text = widget.searchQuery;
    fetchBooks(search: widget.searchQuery);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchBooks({String search = ''}) async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final data = await apiService.getStudentBooks(search: search);
      if (!mounted) return;

      setState(() {
        books = sanitizeListOfMaps(List.from(data['books'] ?? []));
        borrowed = data['borrowed'] ?? 0;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch books')),
      );
    }
  }

  Future<void> borrowBook(int bookId) async {
    if (!mounted) return;

    if (borrowed >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have reached the borrow limit (3 books).'),
        ),
      );
      return;
    }

    try {
      final data = await apiService.borrowBook(bookId: bookId);
      if (!mounted) return;

      if (data['success'] == true) {
        await fetchBooks(search: searchController.text);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Borrow request sent ✅')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(safeString(data['message']).isEmpty
                ? 'Failed to borrow book'
                : safeString(data['message'])),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to borrow book')),
      );
    }
  }

  Future<void> navigateTo(String route) async {
    if (!mounted) return;
    await storage.write(key: 'last_route', value: route);

    if (!mounted) return;
    switch (route) {
      case '/student/dashboard':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
        );
        break;
      case '/student/books':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                StudentAllBooksScreen(searchQuery: searchController.text),
          ),
        );
        break;
      case '/student/mybooks':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => StudentMyBooksScreen()),
        );
        break;
      case '/auth/logout':
        await apiService.logout();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        break;
    }
  }

  Widget buildActionButton(Map<String, dynamic> book) {
    if (borrowed >= 3) {
      return const Text(
        'Limit Reached',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      );
    }

    if ((book['available_copies'] ?? 0) > 0) {
      return ElevatedButton(
        onPressed: () => borrowBook(book['id']),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Borrow',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    }

    return const Text(
      'Unavailable',
      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final maxWidth = width > 1100 ? 1100.0 : width * 0.95;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('📚 All Books'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Dashboard',
            onPressed: () => navigateTo('/student/dashboard'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (String value) {
              if (value.isNotEmpty) navigateTo(value);
            },
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem(value: '/student/books', child: Text('All Books')),
              PopupMenuItem(
                  value: '/student/mybooks', child: Text('My Books')),
              PopupMenuItem(value: '/auth/logout', child: Text('Logout')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => fetchBooks(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
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
                        onSubmitted: (_) =>
                            fetchBooks(search: searchController.text),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () =>
                          fetchBooks(search: searchController.text),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('🔍 Search'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Books list
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : books.isEmpty
                        ? const Center(
                            child: Text(
                              'No books in the library yet.',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: books.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final book = books[index];
                              return Card(
                                elevation: 3,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  title: Text(
                                    safeString(book['title']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  subtitle: Builder(builder: (_) {
                                    final author = safeString(book['author']);
                                    final genre = safeString(book['genre']);
                                    final available = safeString(
                                            book['available_copies'])
                                        .isEmpty
                                        ? '0'
                                        : safeString(book['available_copies']);
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '✍️ Author: ${author.isEmpty ? '-' : author}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '🏷️ Genre: ${genre.isEmpty ? '-' : genre}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '📦 Available: $available',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                  trailing: buildActionButton(book),
                                ),
                              );
                            },
                          ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
