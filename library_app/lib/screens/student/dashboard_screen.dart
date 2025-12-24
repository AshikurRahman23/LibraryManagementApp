import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import 'allbooks_screen.dart';
import 'mybooks_screen.dart';
import '../auth/login_screen.dart';

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
  List<Map<String, dynamic>> featuredBooks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      final data = await apiService.getStudentDashboard();
      if (!mounted) return;

      if (data['success'] == true) {
        setState(() {
          studentName = data['user']['name'] ?? '';
          studentId = data['user']['student_id'] ?? '';
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
    await storage.write(key: 'last_route', value: route);
    if (!mounted) return;

    switch (route) {
      case '/student/books':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentAllBooksScreen()),
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

  void searchBooks() {
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
    final width = MediaQuery.of(context).size.width;
    final maxWidth = width > 1100 ? 1100.0 : width * 0.95;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 2,
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
              PopupMenuItem(value: '/student/mybooks', child: Text('My Books')),
              PopupMenuItem(value: '/auth/logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
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
                      const SizedBox(height: 24),

                     // Welcome Card - Standard Clean UI
Card(
  elevation: 3,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        const Icon(
          Icons.person,
          size: 50,
          color: Colors.blueAccent,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $studentName!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Student ID: $studentId',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ],
    ),
  ),
),


                      const SizedBox(height: 24),

                     // Improved Intro Text
Text(
  'Welcome to the Online Library Management System.\n'
  'Discover a wide range of books and effortlessly manage your reading journey.',
  style: TextStyle(
    fontSize: 16,
    height: 1.6, // slightly more spacing for readability
    color: Colors.grey.shade800, // softer than black
    fontWeight: FontWeight.w500, // medium weight for a modern look
  ),
  textAlign: TextAlign.start, // ensures alignment looks neat
),


                      const SizedBox(height: 24),

                      // Search Bar
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                hintText:
                                    'Search books by title, author, genre...',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onSubmitted: (_) => searchBooks(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: searchBooks,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('🔍 Search'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Featured Books
                      const Text(
                        '🌟 Featured Books',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      featuredBooks.isEmpty
                          ? const Text('No featured books available.')
                          : SizedBox(
                              height: 400,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: featuredBooks.length,
                                itemBuilder: (context, index) {
                                  final book = featuredBooks[index];
                                  return Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.book_outlined,
                                        color: Colors.blueAccent,
                                      ),
                                      title: Text(
                                        book['title'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '– ${book['author'] ?? '-'}',
                                        style: const TextStyle(
                                          color: Colors.black87,
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
                          children: const [
                            Text(
                              '© Online Library Management System',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Contact: library@university.edu | +880-123-456789',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
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
