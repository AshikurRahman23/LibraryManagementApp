import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../theme/app_theme.dart';
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
    _saveCurrentRoute();
    _fetchSuggested();
  }

  Future<void> _saveCurrentRoute() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'last_route', value: '/admin/suggested-books');
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
    final colorScheme = Theme.of(context).colorScheme;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Are you sure?'),
        content: Text('Delete suggestion: "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
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
        case '/admin/payments':
        Navigator.pushReplacementNamed(context, '/admin/payments');
        break;
      case '/auth/logout':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggested Books'),
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchSuggested, tooltip: 'Refresh'),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.getMaxContentWidth(context),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: loading
                ? CircularProgressIndicator(color: colorScheme.primary)
                : error != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                          const SizedBox(height: 16),
                          Text(
                            error!,
                            style: textTheme.bodyLarge?.copyWith(color: colorScheme.error),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _fetchSuggested,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          TextField(
                            controller: searchController,
                            onChanged: (_) => _applySearch(),
                            decoration: InputDecoration(
                              hintText: 'Search by title',
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
                          filtered.isEmpty
                              ? Expanded(
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          size: 64,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No suggested books',
                                          style: textTheme.bodyLarge?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Expanded(
                                  child: ListView.separated(
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                                    itemBuilder: (_, index) {
                                      final s = filtered[index];
                                      final title = s['title'] ?? '(no title)';
                                      final suggestedAt = _formatDate(s['suggested_at']);

                                      return Card(
                                        elevation: 0,
                                        color: colorScheme.surfaceContainerLow,
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          title: Text(
                                            title,
                                            style: textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              'Suggested: $suggestedAt',
                                              style: textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          trailing: IconButton(
                                            icon: Icon(Icons.delete_outline, color: colorScheme.error),
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
