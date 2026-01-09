import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'student_screen.dart';
import 'request_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../utils/js_safe.dart';

class AdminBooksScreen extends StatefulWidget {
  const AdminBooksScreen({super.key});

  @override
  State<AdminBooksScreen> createState() => _AdminBooksScreenState();
}

class _AdminBooksScreenState extends State<AdminBooksScreen> {
  final ApiService api = ApiService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController addTitleController = TextEditingController();
  final TextEditingController addAuthorController = TextEditingController();
  final TextEditingController addTotalController = TextEditingController();
  final TextEditingController addGenreController = TextEditingController();

  final TextEditingController editTitleController = TextEditingController();
  final TextEditingController editAuthorController = TextEditingController();
  final TextEditingController editTotalController = TextEditingController();
  final TextEditingController editGenreController = TextEditingController();

  List<Map<String, dynamic>> books = [];
  List<Map<String, dynamic>> filteredBooks = [];
  int? editingBookId;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _saveCurrentRoute();
    searchController.addListener(_onSearchChanged);
    fetchBooks();
  }

  Future<void> _saveCurrentRoute() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'last_route', value: '/admin/books');
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    addTitleController.dispose();
    addAuthorController.dispose();
    addTotalController.dispose();
    addGenreController.dispose();
    editTitleController.dispose();
    editAuthorController.dispose();
    editTotalController.dispose();
    editGenreController.dispose();
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

  Future<void> fetchBooks([String? search]) async {
    try {
      if (mounted) setState(() => loading = true);
      final data = await api.getAllBooks();
      if (!mounted) return;

      if (data['success'] == true) {
        List<Map<String, dynamic>> allBooks =
            sanitizeListOfMaps(List.from(data['books'] ?? []));

        if (mounted) {
          setState(() {
            books = allBooks;
            filteredBooks = List.from(allBooks);
          });
          _onSearchChanged();
        }
      }
    } catch (e) {
      debugPrint('Fetch books error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> addBook() async {
    if (addTitleController.text.isEmpty ||
        addAuthorController.text.isEmpty ||
        addTotalController.text.isEmpty ||
        addGenreController.text.isEmpty) return;

    final data = await api.addBook(
      title: addTitleController.text,
      author: addAuthorController.text,
      totalCopies: int.tryParse(addTotalController.text) ?? 0,
      genre: addGenreController.text,
    );

    if (!mounted) return;

    if (data['success'] == true) {
      fetchBooks();
      addTitleController.clear();
      addAuthorController.clear();
      addTotalController.clear();
      addGenreController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Book added successfully')));
    }
  }

  Future<void> updateBook() async {
    if (editingBookId == null) return;

    final data = await api.updateBook(
      id: editingBookId!,
      title: editTitleController.text,
      author: editAuthorController.text,
      totalCopies: int.tryParse(editTotalController.text) ?? 0,
      genre: editGenreController.text,
    );

    if (!mounted) return;

    if (data['success'] == true) {
      fetchBooks();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Book updated successfully')));
    }
  }

  Future<void> deleteBook(int id) async {
    final data = await api.deleteBook(id: id);
    if (!mounted) return;

    if (data['success'] == true) {
      fetchBooks();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Book deleted successfully')));
    }
  }

  void openEditModal(Map<String, dynamic> book) {
    editingBookId = book['id'];
    editTitleController.text = safeString(book['title']);
    editAuthorController.text = safeString(book['author']);
    editTotalController.text = safeString(book['total_copies']).isEmpty
        ? ''
        : safeString(book['total_copies']);
    editGenreController.text = safeString(book['genre']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update Book'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: editTitleController,
                  decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 12),
              TextField(
                  controller: editAuthorController,
                  decoration: const InputDecoration(labelText: 'Author')),
              const SizedBox(height: 12),
              TextField(
                  controller: editTotalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Total Copies')),
              const SizedBox(height: 12),
              TextField(
                  controller: editGenreController,
                  decoration: const InputDecoration(labelText: 'Genre')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: updateBook, child: const Text('Update')),
        ],
      ),
    );
  }

  void navigateTo(String route) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'last_route', value: route);
    if (!mounted) return;

    switch (route) {
      case '/admin/dashboard':
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => AdminDashboardScreen()));
        break;
      case '/admin/students':
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => AdminStudentsScreen()));
        break;
      case '/admin/loans':
        Navigator.pushReplacementNamed(context, '/admin/loans');
        break;
      case '/admin/requests':
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => AdminRequestsScreen()));
        break;
      case '/admin/suggested-books':
        Navigator.pushReplacementNamed(context, '/admin/suggested-books');
        break;
      case '/admin/payments':
        Navigator.pushReplacementNamed(context, '/admin/payments');
        break;
      case '/auth/logout':
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => LoginScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Books'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              icon: const Icon(Icons.home_outlined),
              tooltip: 'Dashboard',
              onPressed: () => navigateTo('/admin/dashboard')),
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
            onPressed: () => fetchBooks(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.getMaxContentWidth(context),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Add Book Form
                      Card(
                        elevation: 0,
                        color: colorScheme.surfaceContainerLow,
                        child: ExpansionTile(
                          title: Text(
                            'Add New Book',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          leading: Icon(
                            Icons.add_circle_outline,
                            color: colorScheme.primary,
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  TextField(
                                      controller: addTitleController,
                                      decoration: const InputDecoration(labelText: 'Title')),
                                  const SizedBox(height: 12),
                                  TextField(
                                      controller: addAuthorController,
                                      decoration: const InputDecoration(labelText: 'Author')),
                                  const SizedBox(height: 12),
                                  TextField(
                                      controller: addTotalController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Total Copies')),
                                  const SizedBox(height: 12),
                                  TextField(
                                      controller: addGenreController,
                                      decoration: const InputDecoration(labelText: 'Genre')),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: addBook,
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add Book'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Search Bar
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by title, author, or genre',
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
                      // Books List
                      loading
                          ? CircularProgressIndicator(color: colorScheme.primary)
                          : ListView.builder(
                              itemCount: filteredBooks.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (_, index) {
                                final book = filteredBooks[index];
                                return Card(
                                  elevation: 0,
                                  color: colorScheme.surfaceContainerLow,
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    title: Text(
                                      book['title'],
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
                                          'Author: ${book['author'] ?? '-'}',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          'Genre: ${book['genre'] ?? '-'}',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: colorScheme.secondaryContainer,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Total: ${book['total_copies'] ?? 0} | Available: ${book['available_copies'] ?? 0}',
                                            style: textTheme.labelMedium?.copyWith(
                                              color: colorScheme.onSecondaryContainer,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                            icon: Icon(Icons.edit_outlined, color: colorScheme.primary),
                                            onPressed: () => openEditModal(book)),
                                        IconButton(
                                            icon: Icon(Icons.delete_outline, color: colorScheme.error),
                                            onPressed: () => deleteBook(book['id'])),
                                      ],
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
