import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../utils/js_safe.dart';
import '../../theme/app_theme.dart';
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
    _saveCurrentRoute();
    _fetchSuggested();
  }

  Future<void> _saveCurrentRoute() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'last_route', value: '/superadmin/suggested-books');
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
          FilledButton.tonalIcon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
            ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxWidth = Breakpoints.getMaxContentWidth(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggested Books'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Dashboard',
            onPressed: () => navigateTo('/superadmin/dashboard'),
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
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: loading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : error != null
                    ? Card(
                        elevation: 0,
                        color: colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: colorScheme.onErrorContainer),
                              const SizedBox(height: 12),
                              Text(
                                error!,
                                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onErrorContainer),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _fetchSuggested,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              )
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          TextField(
                            controller: searchController,
                            onChanged: (_) => _applySearch(),
                            decoration: InputDecoration(
                              hintText: 'Search by title',
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
                          filtered.isEmpty
                              ? Card(
                                  elevation: 0,
                                  color: colorScheme.surfaceContainerLow,
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle_outline, size: 48, color: colorScheme.primary),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No suggested books',
                                          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
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
                                        elevation: 0,
                                        color: colorScheme.surfaceContainerLow,
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          leading: Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: colorScheme.secondaryContainer,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(Icons.auto_stories_outlined, color: colorScheme.onSecondaryContainer),
                                          ),
                                          title: Text(
                                            title,
                                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                          ),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(top: 6.0),
                                            child: Row(
                                              children: [
                                                Icon(Icons.schedule, size: 14, color: colorScheme.onSurfaceVariant),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'Suggested: $suggestedAt',
                                                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
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
