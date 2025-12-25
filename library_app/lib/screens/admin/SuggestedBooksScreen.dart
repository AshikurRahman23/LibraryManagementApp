import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../utils/js_safe.dart';
import 'dashboard_screen.dart';
import 'book_screen.dart';
import 'request_screen.dart';
import 'student_screen.dart';
import '../../screens/auth/login_screen.dart';

class SuggestedBooksScreen extends StatefulWidget {
  const SuggestedBooksScreen({super.key});

  @override
  State<SuggestedBooksScreen> createState() => _SuggestedBooksScreenState();
}

class _SuggestedBooksScreenState extends State<SuggestedBooksScreen> {
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
      case '/admin/dashboard':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminDashboardScreen()));
        break;
      case '/admin/students':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminStudentsScreen()));
        break;
      case '/admin/books':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminBooksScreen()));
        break;
      case '/admin/loans':
        Navigator.pushReplacementNamed(context, '/admin/loans');
        break;
      case '/admin/requests':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminRequestsScreen()));
        break;
      case '/admin/suggested-books':
        if (ModalRoute.of(context)?.settings.name == '/admin/suggested-books') {
          if (!mounted) return;
          _fetchSuggested();
        } else {
          Navigator.pushReplacementNamed(context, '/admin/suggested-books');
        }
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
        title: const Text('Suggested Books'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Dashboard',
            onPressed: () => navigateTo('/admin/dashboard'),
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
              PopupMenuItem(value: '/auth/logout', child: Text('Logout')),
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
