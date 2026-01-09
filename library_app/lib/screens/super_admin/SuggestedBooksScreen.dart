import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../utils/js_safe.dart';
import 'book_screen.dart' as super_admin_book;
import 'request_screen.dart' as super_admin_request;
import 'student_screen.dart' as super_admin_student;
import '../../screens/auth/login_screen.dart';

typedef SuperAdminBooksScreen = super_admin_book.SuperAdminBooksScreen;
typedef SuperAdminRequestsScreen = super_admin_request.SuperAdminRequestsScreen;
typedef SuperAdminStudentsScreen = super_admin_student.SuperAdminStudentsScreen;

class SuperAdminSuggestedBooksScreen extends StatefulWidget {
  const SuperAdminSuggestedBooksScreen({super.key});

  @override
  State<SuperAdminSuggestedBooksScreen> createState() => _SuperAdminSuggestedBooksScreenState();
}

class _SuperAdminSuggestedBooksScreenState extends State<SuperAdminSuggestedBooksScreen> {
  final ApiService api = ApiService();
  bool loading = true;
  List<Map<String, dynamic>> suggestions = [];
  List<Map<String, dynamic>> filtered = [];
  String? error;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSuggested();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSuggested() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await api.getSuggestedBooks();
      if (!mounted) return;

      if (res['success'] == true) {
        final rows = sanitizeListOfMaps(List.from(res['suggestedBooks'] ?? []));
        setState(() {
          suggestions = rows;
          filtered = List<Map<String, dynamic>>.from(rows);
        });
      } else {
        setState(() {
          suggestions = [];
          filtered = [];
          error = safeString(res['message']).isEmpty ? 'Failed to load suggestions' : safeString(res['message']);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => error = 'Network or server error');
      debugPrint('Error fetching suggested books: $e');
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  void _applySearch() {
    if (!mounted) return;
    final q = searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => filtered = List<Map<String, dynamic>>.from(suggestions));
      return;
    }

    setState(() {
      filtered = suggestions.where((s) {
        final t = (s['title'] ?? '').toString().toLowerCase();
        return t.contains(q);
      }).toList();
    });
  }

  Future<void> _confirmDelete(int id, String title) async {
    if (!mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Are you sure?'),
        content: Text('Delete suggestion: "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (ok == true && mounted) {
      await _deleteSuggestion(id);
    }
  }

  Future<void> _deleteSuggestion(int id) async {
    try {
      final res = await api.deleteSuggestedBook(id: id);
      if (!mounted) return;

      if (res['success'] == true) {
        setState(() {
          suggestions.removeWhere((s) => s['id'] == id);
          filtered.removeWhere((s) => s['id'] == id);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suggestion deleted')));
        return;
      }

      final msg = (res['message'] != null) ? res['message'].toString() : 'Failed to delete suggestion';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      debugPrint('Delete suggestion error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network or server error')));
    }
  }

  String _formatDate(Object? ts) => safeDateFormatted(ts);

  void navigateTo(String route) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'last_route', value: route);
    if (!mounted) return;

    switch (route) {
      case '/superadmin/dashboard':
        Navigator.pushReplacementNamed(context, '/superadmin/dashboard');
        break;
      case '/superadmin/students':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SuperAdminStudentsScreen()));
        break;
      case '/superadmin/books':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SuperAdminBooksScreen()));
        break;
      case '/superadmin/loans':
        Navigator.pushReplacementNamed(context, '/superadmin/loans');
        break;
      case '/superadmin/requests':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SuperAdminRequestsScreen()));
        break;
      case '/superadmin/suggested-books':
        if (ModalRoute.of(context)?.settings.name == '/superadmin/suggested-books') {
          if (!mounted) return;
          _fetchSuggested();
        } else {
          Navigator.pushReplacementNamed(context, '/superadmin/suggested-books');
        }
        break;
      case '/superadmin/admins':
        Navigator.pushReplacementNamed(context, '/superadmin/admins');
        break;
      case '/superadmin/payments':
        Navigator.pushReplacementNamed(context, '/superadmin/payments');
        break;
      case '/auth/logout':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('📚 Suggested Books'),
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchSuggested, tooltip: 'Refresh'),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: loading
                ? const CircularProgressIndicator()
                : error != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(error!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 8),
                          ElevatedButton(onPressed: _fetchSuggested, child: const Text('Retry'))
                        ],
                      )
                    : Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: searchController,
                                  decoration: const InputDecoration(hintText: 'Search by title'),
                                ),
                              ),
                              IconButton(icon: const Icon(Icons.search), onPressed: _applySearch),
                            ],
                          ),
                          const SizedBox(height: 12),
                          filtered.isEmpty
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                                    SizedBox(height: 8),
                                    Text('No suggested books')
                                  ],
                                )
                              : Expanded(
                                  child: ListView.separated(
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                    itemBuilder: (_, index) {
                                      final s = filtered[index];
                                      final title = s['title'] ?? '(no title)';
                                      final suggestedAt = _formatDate(s['suggested_at']);

                                      return Card(
                                        elevation: 2,
                                        child: ListTile(
                                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(top: 6.0),
                                            child: Text('Suggested: $suggestedAt', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                                            tooltip: 'Delete suggestion',
                                            onPressed: () => _confirmDelete(s['id'] as int, title),
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
