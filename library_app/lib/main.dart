import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/dashboard_screen.dart';
import 'screens/admin/book_screen.dart';
import 'screens/admin/admin_loans_screen.dart';
import 'screens/admin/student_screen.dart';
import 'screens/admin/request_screen.dart';
import 'screens/admin/SuggestedBooksScreen.dart';
import 'screens/admin/payment_history_screen.dart' as admin_payment;
import 'screens/super_admin/dashboard_screen.dart' as super_admin;
import 'screens/super_admin/admin_management_screen.dart' as super_admin_mgmt;
import 'screens/super_admin/payment_history_screen.dart' as superadmin_payment;
import 'screens/super_admin/book_screen.dart' as superadmin_book;
import 'screens/super_admin/student_screen.dart' as superadmin_student;
import 'screens/super_admin/admin_loans_screen.dart' as superadmin_loans;
import 'screens/super_admin/request_screen.dart' as superadmin_request;
import 'screens/super_admin/SuggestedBooksScreen.dart' as superadmin_suggested;
import 'screens/student/payment_history_screen.dart' as student_payment;
import 'screens/student/dashboard_screen.dart' as student_dash;
import 'screens/student/allbooks_screen.dart';
import 'screens/student/mybooks_screen.dart';
import 'api/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Custom error handler to prevent crashes from JS interop issues on web
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kIsWeb && details.exception.toString().contains('LegacyJavaScriptObject')) {
      // Suppress this specific error on web
      debugPrint('Suppressed JS interop error: ${details.exception}');
      return;
    }
    // Default error handling for other errors
    FlutterError.presentError(details);
  };
  
  runApp(const LibraryApp());
}

class LibraryApp extends StatefulWidget {
  const LibraryApp({super.key});

  @override
  State<LibraryApp> createState() => _LibraryAppState();
}

class _LibraryAppState extends State<LibraryApp> {
  @override
  void initState() {
    super.initState();
    themeController.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Library App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode,

      home: const SplashScreen(), // Temporary loading screen

      // **Remove const for screens with state/controllers**
      routes: {
        // Admin routes
        '/admin/dashboard': (_) => AdminDashboardScreen(),
        '/admin/books': (_) => AdminBooksScreen(),
        '/admin/students': (_) => AdminStudentsScreen(),
        '/admin/loans': (_) => const AdminLoansScreen(),
        '/admin/requests': (_) => AdminRequestsScreen(),
        '/admin/suggested-books': (_) => const SuggestedBooksScreen(),
        '/admin/payments': (_) => const admin_payment.AdminPaymentHistoryScreen(),
        // Super admin routes
        '/superadmin/dashboard': (_) => const super_admin.SuperAdminDashboardScreen(),
        '/superadmin/admins': (_) => const super_admin_mgmt.SuperAdminManagementScreen(),
        '/superadmin/payments': (_) => const superadmin_payment.SuperAdminPaymentHistoryScreen(),
        '/superadmin/books': (_) => const superadmin_book.SuperAdminBooksScreen(),
        '/superadmin/students': (_) => const superadmin_student.SuperAdminStudentsScreen(),
        '/superadmin/loans': (_) => const superadmin_loans.SuperAdminLoansScreen(),
        '/superadmin/requests': (_) => const superadmin_request.SuperAdminRequestsScreen(),
        '/superadmin/suggested-books': (_) => const superadmin_suggested.SuperAdminSuggestedBooksScreen(),
        // Student routes
        '/student/dashboard': (_) => const student_dash.StudentDashboardScreen(),
        '/student/books': (_) => const StudentAllBooksScreen(),
        '/student/mybooks': (_) => const StudentMyBooksScreen(),
        '/student/payments': (_) => const student_payment.StudentPaymentHistoryScreen(),
        // Auth routes
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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_library_rounded,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
