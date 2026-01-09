import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'allbooks_screen.dart';
import 'mybooks_screen.dart';
import 'payment_history_screen.dart';
import '../auth/login_screen.dart';

class StudentEditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentMobileNo;
  final String studentId;
  final String email;

  const StudentEditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentMobileNo,
    required this.studentId,
    required this.email,
  });

  @override
  State<StudentEditProfileScreen> createState() => _StudentEditProfileScreenState();
}

class _StudentEditProfileScreenState extends State<StudentEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final ApiService apiService = ApiService();
  
  late TextEditingController nameController;
  late TextEditingController mobileController;
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  bool isLoading = false;
  bool isPasswordLoading = false;
  bool showCurrentPassword = false;
  bool showNewPassword = false;
  bool showConfirmPassword = false;
  String? errorMessage;
  String? successMessage;
  String? passwordErrorMessage;
  String? passwordSuccessMessage;

  @override
  void initState() {
    super.initState();
    _saveCurrentRoute();
    nameController = TextEditingController(text: widget.currentName);
    mobileController = TextEditingController(text: widget.currentMobileNo);
  }

  Future<void> _saveCurrentRoute() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'last_route', value: '/student/dashboard');
  }

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
    });

    try {
      final result = await apiService.updateStudentProfile(
        name: nameController.text.trim(),
        mobileNo: mobileController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          successMessage = result['message'] ?? 'Profile updated successfully';
          isLoading = false;
        });

        // Show success message and navigate back after a short delay
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
        );
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to update profile';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'An error occurred. Please try again.';
        isLoading = false;
      });
    }
  }

  Future<void> changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() {
      isPasswordLoading = true;
      passwordErrorMessage = null;
      passwordSuccessMessage = null;
    });

    try {
      final result = await apiService.changeStudentPassword(
        currentPassword: currentPasswordController.text,
        newPassword: newPasswordController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          passwordSuccessMessage = result['message'] ?? 'Password changed successfully';
          isPasswordLoading = false;
        });
        // Clear password fields
        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
      } else {
        setState(() {
          passwordErrorMessage = result['message'] ?? 'Failed to change password';
          isPasswordLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        passwordErrorMessage = 'An error occurred. Please try again.';
        isPasswordLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxWidth = Breakpoints.getMaxContentWidth(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Dashboard',
            onPressed: () {
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              if (!mounted) return;
              await apiService.logout();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.logout),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (String value) {
              if (!mounted) return;
              switch (value) {
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
                case '/student/payments':
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentPaymentHistoryScreen()),
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem(value: '/student/books', child: Text('All Books')),
              PopupMenuItem(value: '/student/mybooks', child: Text('My Books')),
              PopupMenuItem(value: '/student/payments', child: Text('Payments')),
            ],
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Profile Header Card
                  Card(
                    elevation: 0,
                    color: colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Icon(
                              Icons.person_outline,
                              size: 48,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit Your Profile',
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Update your personal information',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Read-only fields
                  Text(
                    'Account Information',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Student ID (read-only)
                  TextFormField(
                    initialValue: widget.studentId,
                    readOnly: true,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Student ID',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      helperText: 'Student ID cannot be changed',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email (read-only)
                  TextFormField(
                    initialValue: widget.email,
                    readOnly: true,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      helperText: 'Email cannot be changed',
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Editable fields
                  Text(
                    'Personal Information',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name field
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Mobile Number field
                  TextFormField(
                    controller: mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'e.g., +880-123-456789',
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        // Basic phone validation
                        if (value.length < 10) {
                          return 'Please enter a valid mobile number';
                        }
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Error message
                  if (errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(color: colorScheme.onErrorContainer),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Success message
                  if (successMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              successMessage!,
                              style: TextStyle(color: Colors.green.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Update Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isLoading ? null : updateProfile,
                      icon: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(isLoading ? 'Updating...' : 'Update Profile'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const StudentDashboardScreen()),
                              );
                            },
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Divider
                  Divider(color: colorScheme.outlineVariant),

                  const SizedBox(height: 32),

                  // Change Password Section
                  Text(
                    'Change Password',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Form(
                    key: _passwordFormKey,
                    child: Column(
                      children: [
                        // Current Password
                        TextFormField(
                          controller: currentPasswordController,
                          obscureText: !showCurrentPassword,
                          decoration: InputDecoration(
                            labelText: 'Current Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showCurrentPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  showCurrentPassword = !showCurrentPassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your current password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // New Password
                        TextFormField(
                          controller: newPasswordController,
                          obscureText: !showNewPassword,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showNewPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  showNewPassword = !showNewPassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a new password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Confirm New Password
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: !showConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm New Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  showConfirmPassword = !showConfirmPassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your new password';
                            }
                            if (value != newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Password Error message
                        if (passwordErrorMessage != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: colorScheme.onErrorContainer),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    passwordErrorMessage!,
                                    style: TextStyle(
                                        color: colorScheme.onErrorContainer),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Password Success message
                        if (passwordSuccessMessage != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    color: Colors.green.shade800),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    passwordSuccessMessage!,
                                    style:
                                        TextStyle(color: Colors.green.shade800),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Change Password Button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonal(
                            onPressed: isPasswordLoading ? null : changePassword,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isPasswordLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.key_outlined),
                                      SizedBox(width: 8),
                                      Text('Change Password'),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
