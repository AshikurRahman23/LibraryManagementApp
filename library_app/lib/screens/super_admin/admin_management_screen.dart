import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../theme/app_theme.dart';
import 'book_screen.dart' as super_admin_book;
import 'student_screen.dart' as super_admin_student;
import 'request_screen.dart' as super_admin_request;
import '../../screens/auth/login_screen.dart';

typedef SuperAdminBooksScreen = super_admin_book.SuperAdminBooksScreen;
typedef SuperAdminStudentsScreen = super_admin_student.SuperAdminStudentsScreen;
typedef SuperAdminRequestsScreen = super_admin_request.SuperAdminRequestsScreen;

class SuperAdminManagementScreen extends StatefulWidget {
  const SuperAdminManagementScreen({super.key});

  @override
  State<SuperAdminManagementScreen> createState() => _SuperAdminManagementScreenState();
}

class _SuperAdminManagementScreenState extends State<SuperAdminManagementScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _admins = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _saveCurrentRoute();
    _loadAdmins();
  }

  Future<void> _saveCurrentRoute() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'last_route', value: '/superadmin/admins');
  }

  Future<void> _loadAdmins({String? search}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _api.getAllAdmins(search: search);
      if (response['success'] == true) {
        setState(() {
          _admins = response['admins'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load admins';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error: $e';
        _loading = false;
      });
    }
  }

  void _showAddAdminDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final mobileController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Admin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password *',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mobileController,
                decoration: const InputDecoration(
                  labelText: 'Mobile No',
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  emailController.text.isEmpty ||
                  passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill required fields')),
                );
                return;
              }

              Navigator.pop(ctx);

              final response = await _api.createAdmin(
                name: nameController.text,
                email: emailController.text,
                password: passwordController.text,
                mobileNo: mobileController.text.isNotEmpty
                    ? mobileController.text
                    : null,
              );

              if (response['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Admin created successfully')),
                );
                _loadAdmins();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text(response['message'] ?? 'Failed to create admin')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditAdminDialog(Map<String, dynamic> admin) {
    final nameController = TextEditingController(text: admin['name']);
    final emailController = TextEditingController(text: admin['email']);
    final mobileController =
        TextEditingController(text: admin['mobile_no'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Admin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mobileController,
                decoration: const InputDecoration(
                  labelText: 'Mobile No',
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isEmpty || emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name and email are required')),
                );
                return;
              }

              Navigator.pop(ctx);

              final response = await _api.updateAdmin(
                id: admin['id'],
                name: nameController.text,
                email: emailController.text,
                mobileNo: mobileController.text.isNotEmpty
                    ? mobileController.text
                    : null,
              );

              if (response['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Admin updated successfully')),
                );
                _loadAdmins();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text(response['message'] ?? 'Failed to update admin')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(Map<String, dynamic> admin) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change Password for ${admin['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (passwordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Password must be at least 6 characters')),
                );
                return;
              }

              if (passwordController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              Navigator.pop(ctx);

              final response = await _api.updateAdminPassword(
                id: admin['id'],
                password: passwordController.text,
              );

              if (response['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password updated successfully')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          response['message'] ?? 'Failed to update password')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> admin) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Admin'),
        content: Text('Are you sure you want to delete ${admin['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              final response = await _api.deleteAdmin(id: admin['id']);

              if (response['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Admin deleted successfully')),
                );
                _loadAdmins();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text(response['message'] ?? 'Failed to delete admin')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _navigateTo(String route) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'last_route', value: route);
    if (!mounted) return;

    switch (route) {
      case '/superadmin/dashboard':
        Navigator.pushReplacementNamed(context, '/superadmin/dashboard');
        break;
      case '/superadmin/books':
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const SuperAdminBooksScreen()));
        break;
      case '/superadmin/students':
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const SuperAdminStudentsScreen()));
        break;
      case '/superadmin/loans':
        Navigator.pushReplacementNamed(context, '/superadmin/loans');
        break;
      case '/superadmin/requests':
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const SuperAdminRequestsScreen()));
        break;
      case '/superadmin/suggested-books':
        Navigator.pushReplacementNamed(context, '/superadmin/suggested-books');
        break;
      case '/superadmin/admins':
        // Already on this screen
        break;
      case '/superadmin/payments':
        Navigator.pushReplacementNamed(context, '/superadmin/payments');
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
    final maxWidth = Breakpoints.getMaxContentWidth(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Admins'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Dashboard',
            onPressed: () => _navigateTo('/superadmin/dashboard'),
          ),
           IconButton(
            tooltip: 'Logout',
            onPressed: () {
              if (!mounted) return;
              _navigateTo('/auth/logout');
            },
             icon: const Icon(Icons.logout)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: _navigateTo,
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
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _loadAdmins(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAdminDialog,
        child: const Icon(Icons.add),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search admins...',
                    prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                            onPressed: () {
                              _searchController.clear();
                              _loadAdmins();
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    _loadAdmins(search: value);
                  },
                ),
              ),

              // Admin list
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                    : _error != null
                        ? Card(
                            elevation: 0,
                            color: colorScheme.errorContainer,
                            margin: const EdgeInsets.all(16),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline, size: 48, color: colorScheme.onErrorContainer),
                                  const SizedBox(height: 12),
                                  Text(
                                    _error!,
                                    style: textTheme.bodyLarge?.copyWith(color: colorScheme.onErrorContainer),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () => _loadAdmins(),
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _admins.isEmpty
                            ? Card(
                                elevation: 0,
                                color: colorScheme.surfaceContainerLow,
                                margin: const EdgeInsets.all(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.admin_panel_settings_outlined, size: 48, color: colorScheme.onSurfaceVariant),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No admins found',
                                        style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _admins.length,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemBuilder: (context, index) {
                                  final admin = _admins[index];
                                  return Card(
                                    elevation: 0,
                                    color: colorScheme.surfaceContainerLow,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(12),
                                      leading: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            (admin['name'] ?? 'A')[0].toUpperCase(),
                                            style: textTheme.titleLarge?.copyWith(
                                              color: colorScheme.onPrimaryContainer,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        admin['name'] ?? 'Unknown',
                                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.email_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  admin['email'] ?? '',
                                                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (admin['mobile_no'] != null) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.phone_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    admin['mobile_no'],
                                                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      isThreeLine: admin['mobile_no'] != null,
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (value) {
                                          switch (value) {
                                            case 'edit':
                                              _showEditAdminDialog(admin);
                                              break;
                                            case 'password':
                                              _showChangePasswordDialog(admin);
                                              break;
                                            case 'delete':
                                              _showDeleteConfirmation(admin);
                                              break;
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: ListTile(
                                              leading: Icon(Icons.edit_outlined, color: colorScheme.onSurface),
                                              title: const Text('Edit'),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'password',
                                            child: ListTile(
                                              leading: Icon(Icons.lock_outline, color: colorScheme.onSurface),
                                              title: const Text('Change Password'),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: ListTile(
                                              leading: Icon(Icons.delete_outline, color: colorScheme.error),
                                              title: Text('Delete', style: TextStyle(color: colorScheme.error)),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ],
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
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
