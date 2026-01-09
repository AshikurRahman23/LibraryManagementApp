import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import 'allbooks_screen.dart';
import 'mybooks_screen.dart';
import 'edit_profile_screen.dart';
import '../auth/login_screen.dart';
import '../../utils/js_safe.dart';
import 'payment_history_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final TextEditingController searchController = TextEditingController();
  final ApiService apiService = ApiService();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  String studentName = '';
  String studentId = '';
  String studentEmail = '';
  String studentMobile = '';
  List<Map<String, dynamic>> featuredBooks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _saveCurrentRoute();
    fetchDashboardData();
  }

  Future<void> _saveCurrentRoute() async {
    await storage.write(key: 'last_route', value: '/student/dashboard');
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchDashboardData() async {
    try {
      final data = await apiService.getStudentDashboard();
      if (!mounted) return;

      if (data['success'] == true) {
        setState(() {
          studentName = data['user']['name'] ?? '';
          studentId = data['user']['student_id'] ?? '';
          studentEmail = data['user']['email'] ?? '';
          studentMobile = data['user']['mobile_no'] ?? '';
          featuredBooks = List<Map<String, dynamic>>.from(
            data['featuredBooks'] ?? [],
          );
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
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
      case '/student/payments':
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentPaymentHistoryScreen()),
        );
        break;
      case '/student/profile':
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StudentEditProfileScreen(
              currentName: studentName,
              currentMobileNo: studentMobile,
              studentId: studentId,
              email: studentEmail,
            ),
          ),
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

  void searchBooks() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StudentAllBooksScreen(searchQuery: searchController.text),
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
        title: const Text('Student Dashboard'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(themeController.themeModeIcon),
            tooltip: 'Theme: ${themeController.themeModeLabel}',
            onPressed: () => themeController.cycleThemeMode(),
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Dashboard',
            onPressed: () {
              if (!mounted) return;
              navigateTo('/student/dashboard');
            },
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
            onSelected: (String value) {
              if (!mounted) return;
              if (value.isNotEmpty) navigateTo(value);
            },
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem(value: '/student/books', child: Text('All Books')),
              PopupMenuItem(value: '/student/mybooks', child: Text('My Books')),
              PopupMenuItem(value: '/student/payments', child: Text('Payments')),
            ],
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Welcome Card
                      Card(
                        elevation: 0,
                        color: colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.person_outline,
                                  size: 40,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Hello, $studentName!',
                                            style: textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit_outlined,
                                            color: colorScheme.primary,
                                            size: 20,
                                          ),
                                          tooltip: 'Edit Profile',
                                          onPressed: () => navigateTo('/student/profile'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Student ID: $studentId',
                                        style: textTheme.labelLarge?.copyWith(
                                          color: colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                
                      const SizedBox(height: 24),

                      // Search Bar
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                hintText: 'Search books by title, author, genre...',
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              onSubmitted: (_) => searchBooks(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: searchBooks,
                            icon: const Icon(Icons.search, size: 20),
                            label: const Text('Search'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Featured Books
                      Text(
                        'Featured Books',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),

                      featuredBooks.isEmpty
                          ? Card(
                              elevation: 0,
                              color: colorScheme.surfaceContainerLow,
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.library_books_outlined,
                                        size: 48,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No featured books available.',
                                        style: textTheme.bodyLarge?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : SizedBox(
                              height: 400,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: featuredBooks.length,
                                itemBuilder: (context, index) {
                                  final book = featuredBooks[index];
                                  return Card(
                                    elevation: 0,
                                    color: colorScheme.surfaceContainerLow,
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.book_outlined,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                      title: Text(
                                        safeString(book['title']),
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '– ${safeString(book['author']).isEmpty ? '-' : safeString(book['author'])}',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                      const SizedBox(height: 32),

                      // Footer
                      Center(
                        child: Column(
                          children: [
                            Text(
                              '© Online Library Management System',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Contact: library@university.edu | +880-123-456789',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
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
