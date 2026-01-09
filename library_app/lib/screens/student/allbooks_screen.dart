import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../utils/js_safe.dart';
import '../../theme/app_theme.dart';
import 'mybooks_screen.dart';
import 'dashboard_screen.dart';
import '../auth/login_screen.dart';
import 'payment_history_screen.dart';

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
  List<Map<String, dynamic>> filteredBooks = [];
  int borrowed = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _saveCurrentRoute();
    searchController.text = widget.searchQuery;
    searchController.addListener(_onSearchChanged);
    fetchBooks(search: widget.searchQuery);
  }

  Future<void> _saveCurrentRoute() async {
    await storage.write(key: 'last_route', value: '/student/books');
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
        filteredBooks = List.from(books);
      } else {
        filteredBooks = books.where((b) {
          return b['title'].toString().toLowerCase().contains(query) ||
              b['author'].toString().toLowerCase().contains(query) ||
              b['genre'].toString().toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> fetchBooks({String search = ''}) async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final data = await apiService.getStudentBooks(search: search);
      if (!mounted) return;

      setState(() {
        books = sanitizeListOfMaps(List.from(data['books'] ?? []));
        filteredBooks = List.from(books);
        borrowed = data['borrowed'] ?? 0;
        isLoading = false;
      });
      _onSearchChanged();
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
        case '/student/payments':
           Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentPaymentHistoryScreen()),
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

  Widget buildActionButton(Map<String, dynamic> book, ColorScheme colorScheme, TextTheme textTheme) {
    if (borrowed >= 3) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Limit Reached',
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onErrorContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if ((book['available_copies'] ?? 0) > 0) {
      return FilledButton(
        onPressed: () => borrowBook(book['id']),
        child: const Text('Borrow'),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Unavailable',
        style: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxWidth = Breakpoints.getMaxContentWidth(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Books'),
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
            onPressed: () {
              if (!mounted) return;
              navigateTo('/auth/logout');
            },
             icon: const Icon(Icons.logout)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (String value) {
              if (value.isNotEmpty) navigateTo(value);
            },
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem(value: '/student/books', child: Text('All Books')),
              PopupMenuItem(
                  value: '/student/mybooks', child: Text('My Books')),
              PopupMenuItem(
                  value: '/student/payments', child: Text('Payments')),
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
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search books by title, author...',
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

                // Books list
                isLoading
                    ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                    : filteredBooks.isEmpty
                        ? Card(
                            elevation: 0,
                            color: colorScheme.surfaceContainerLow,
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.library_books_outlined, size: 48, color: colorScheme.onSurfaceVariant),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No books in the library yet.',
                                      style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredBooks.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final book = filteredBooks[index];
                              return Card(
                                elevation: 0,
                                color: colorScheme.surfaceContainerLow,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Text(
                                    safeString(book['title']),
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
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
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.person_outline, size: 16, color: colorScheme.onSurfaceVariant),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                'Author: ${author.isEmpty ? '-' : author}',
                                                style: textTheme.bodyMedium?.copyWith(
                                                  color: colorScheme.onSurfaceVariant,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.label_outline, size: 16, color: colorScheme.onSurfaceVariant),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                'Genre: ${genre.isEmpty ? '-' : genre}',
                                                style: textTheme.bodyMedium?.copyWith(
                                                  color: colorScheme.onSurfaceVariant,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.inventory_2_outlined, size: 16, color: colorScheme.primary),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                'Available: $available',
                                                style: textTheme.bodyMedium?.copyWith(
                                                  color: colorScheme.primary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  }),
                                  trailing: buildActionButton(book, colorScheme, textTheme),
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
