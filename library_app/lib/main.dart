import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/dashboard_screen.dart';
import 'screens/admin/book_screen.dart';
import 'screens/admin/admin_loans_screen.dart';
import 'screens/admin/student_screen.dart';
import 'screens/admin/request_screen.dart';
import 'screens/admin/SuggestedBooksScreen.dart';
import 'api/api_service.dart';

void main() {
  runApp(const LibraryApp());
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Library App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamilyFallback: ['Arial', 'sans-serif']),
          bodyLarge: TextStyle(fontFamilyFallback: ['Arial', 'sans-serif']),
          bodySmall: TextStyle(fontFamilyFallback: ['Arial', 'sans-serif']),
        ),
      ),

      home: const SplashScreen(), // Temporary loading screen

      // **Remove const for screens with state/controllers**
      routes: {
        '/admin/dashboard': (_) => AdminDashboardScreen(),
        '/admin/books': (_) => AdminBooksScreen(),
        '/admin/students': (_) => AdminStudentsScreen(),
        '/admin/loans': (_) => const AdminLoansScreen(),
        '/admin/requests': (_) => AdminRequestsScreen(),
        '/admin/suggested-books': (_) => const SuggestedBooksScreen(),
        '/login': (_) => LoginScreen(),
      },
    );
  }
}

/// Splash screen to decide initial route
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ApiService api = ApiService();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkLoginAndNavigate();
  }

  Future<void> _checkLoginAndNavigate() async {
    try {
      bool loggedIn = await api.isLoggedIn();
      String route = '/login';

      if (loggedIn) {
        String? lastRoute = await storage.read(key: 'last_route');
        route = lastRoute ?? '/admin/dashboard';
      }

      // Navigate after first frame
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(route);
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
