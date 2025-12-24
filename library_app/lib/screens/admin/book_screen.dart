import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import 'dashboard_screen.dart';
import 'request_screen.dart';
import 'student_screen.dart';
import '../../screens/auth/login_screen.dart';

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
  int? editingBookId;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  Future<void> fetchBooks([String? search]) async {
    try {
      setState(() => loading = true);
      final data = await api.getAllBooks();
      if (data['success'] == true) {
        List<Map<String, dynamic>> allBooks =
            List<Map<String, dynamic>>.from(data['books']);

        if (search != null && search.isNotEmpty) {
          final q = search.toLowerCase();
          allBooks = allBooks.where((b) {
            return b['title'].toString().toLowerCase().contains(q) ||
                b['author'].toString().toLowerCase().contains(q) ||
                b['genre'].toString().toLowerCase().contains(q);
          }).toList();
        }

        setState(() => books = allBooks);
      }
    } catch (e) {
      debugPrint('Fetch books error: $e');
    } finally {
      setState(() => loading = false);
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

    if (data['success'] == true) {
      fetchBooks();
      addTitleController.clear();
      addAuthorController.clear();
      addTotalController.clear();
      addGenreController.clear();
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

    if (data['success'] == true) {
      fetchBooks();
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Book updated successfully')));
    }
  }

  Future<void> deleteBook(int id) async {
    final data = await api.deleteBook(id: id);
    if (data['success'] == true) {
      fetchBooks();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Book deleted successfully')));
    }
  }

  void openEditModal(Map<String, dynamic> book) {
    editingBookId = book['id'];
    editTitleController.text = book['title'];
    editAuthorController.text = book['author'];
    editTotalController.text = book['total_copies'].toString();
    editGenreController.text = book['genre'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update Book'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: editTitleController,
                decoration: const InputDecoration(labelText: 'Title')),
            TextField(
                controller: editAuthorController,
                decoration: const InputDecoration(labelText: 'Author')),
            TextField(
                controller: editTotalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Copies')),
            TextField(
                controller: editGenreController,
                decoration: const InputDecoration(labelText: 'Genre')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(onPressed: updateBook, child: const Text('Update')),
        ],
      ),
    );
  }

  void navigateTo(String route) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'last_route', value: route);

    switch (route) {
      case '/admin/dashboard':
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AdminDashboardScreen()));
        break;
      case '/admin/students':
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AdminStudentsScreen()));
        break;
      case '/admin/loans':
        Navigator.pushReplacementNamed(context, '/admin/loans');
        break;
      case '/admin/requests':
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AdminRequestsScreen()));
        break;
      case '/auth/logout':
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => LoginScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('📚 Manage Books'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              icon: const Icon(Icons.home),
              tooltip: 'Dashboard',
              onPressed: () => navigateTo('/admin/dashboard')),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: navigateTo,
            itemBuilder: (_) => const [
              PopupMenuItem(value: '/admin/books', child: Text('Books')),
              PopupMenuItem(value: '/admin/students', child: Text('Students')),
              PopupMenuItem(value: '/admin/loans', child: Text('Loans')),
              PopupMenuItem(value: '/admin/requests', child: Text('Requests')),
              PopupMenuItem(value: '/auth/logout', child: Text('Logout')),
            ],
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Add Book Form
                      ExpansionTile(
                        title: const Text('Add New Book'),
                        children: [
                          TextField(
                              controller: addTitleController,
                              decoration:
                                  const InputDecoration(labelText: 'Title')),
                          TextField(
                              controller: addAuthorController,
                              decoration:
                                  const InputDecoration(labelText: 'Author')),
                          TextField(
                              controller: addTotalController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Total Copies')),
                          TextField(
                              controller: addGenreController,
                              decoration:
                                  const InputDecoration(labelText: 'Genre')),
                          const SizedBox(height: 8),
                          ElevatedButton(
                              onPressed: addBook, child: const Text('Add Book'))
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Search Bar
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              decoration: const InputDecoration(
                                  hintText:
                                      'Search by title, author, or genre'),
                            ),
                          ),
                          IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () =>
                                  fetchBooks(searchController.text)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Books List
                      loading
                          ? const CircularProgressIndicator()
                          : ListView.builder(
                              itemCount: books.length,
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemBuilder: (_, index) {
                                final book = books[index];
                                return Card(
                                  elevation: 2,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 6),
                                    title: Text(
                                      book['title'],
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: book['author'],
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const TextSpan(
                                            text: ' • ',
                                            style: TextStyle(
                                              color: Colors.black54,
                                              fontSize: 13,
                                            ),
                                          ),
                                          TextSpan(
                                            text: book['genre'],
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: Wrap(
                                      spacing: 4,
                                      children: [
                                        IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: Colors.blueGrey),
                                            onPressed: () =>
                                                openEditModal(book)),
                                        IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.redAccent),
                                            onPressed: () =>
                                                deleteBook(book['id'])),
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
