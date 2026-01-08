import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import 'book_screen.dart';
import 'student_screen.dart';
import 'request_screen.dart';
import '../../screens/auth/login_screen.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _admins = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
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
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password *',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mobileController,
                decoration: const InputDecoration(
                  labelText: 'Mobile No',
                  border: OutlineInputBorder(),
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
          ElevatedButton(
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
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mobileController,
                decoration: const InputDecoration(
                  labelText: 'Mobile No',
                  border: OutlineInputBorder(),
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
          ElevatedButton(
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
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
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
          ElevatedButton(
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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
      case '/admin/dashboard':
        Navigator.pushReplacementNamed(context, '/superadmin/dashboard');
        break;
      case '/admin/books':
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const AdminBooksScreen()));
        break;
      case '/admin/students':
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const AdminStudentsScreen()));
        break;
      case '/admin/loans':
        Navigator.pushReplacementNamed(context, '/admin/loans');
        break;
      case '/admin/requests':
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const AdminRequestsScreen()));
        break;
      case '/admin/suggested-books':
        Navigator.pushReplacementNamed(context, '/admin/suggested-books');
        break;
      case '/superadmin/admins':
        // Already on this screen
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
        title: const Text('👤 Manage Admins'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Dashboard',
            onPressed: () => _navigateTo('/admin/dashboard'),
          ),
           IconButton(
            tooltip: 'logout',
            onPressed: () {
              if (!mounted) return;
              _navigateTo('/auth/logout');
            },
             icon: const Icon(Icons.logout)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: _navigateTo,
            itemBuilder: (_) => const [
              PopupMenuItem(value: '/admin/books', child: Text('Books')),
              PopupMenuItem(value: '/admin/students', child: Text('Students')),
              PopupMenuItem(value: '/admin/loans', child: Text('Loans')),
              PopupMenuItem(value: '/admin/requests', child: Text('Requests')),
              PopupMenuItem(value: '/admin/suggested-books', child: Text('Suggested')),
              PopupMenuItem(value: '/superadmin/admins', child: Text('Manage Admins')),
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
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search admins...',
                    prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
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
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!,
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadAdmins(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _admins.isEmpty
                        ? const Center(child: Text('No admins found'))
                        : ListView.builder(
                            itemCount: _admins.length,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemBuilder: (context, index) {
                              final admin = _admins[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.deepPurple,
                                    child: Text(
                                      (admin['name'] ?? 'A')[0].toUpperCase(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(admin['name'] ?? 'Unknown'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(admin['email'] ?? ''),
                                      if (admin['mobile_no'] != null)
                                        Text(admin['mobile_no']),
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
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: ListTile(
                                          leading: Icon(Icons.edit),
                                          title: Text('Edit'),
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'password',
                                        child: ListTile(
                                          leading: Icon(Icons.lock),
                                          title: Text('Change Password'),
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: ListTile(
                                          leading: Icon(Icons.delete,
                                              color: Colors.red),
                                          title: Text('Delete',
                                              style:
                                                  TextStyle(color: Colors.red)),
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
