// lib/pages/register_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../widgets/app_modal_dialog.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _studentIdController = TextEditingController();

  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // Role selection: 'student' or 'staff' (merchant)
  String _selectedRole = 'student';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _storeNameController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!value.endsWith('@gmail.com')) {
      return 'Please use a Gmail address (@gmail.com)';
    }
    if (value.length < 11) {
      // x@gmail.com = 11 chars minimum
      return 'Please enter a valid Gmail address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (value.length > 16) {
      return 'Password must not exceed 16 characters';
    }
    // Check for at least one letter
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Password must contain at least one letter';
    }
    // Check for at least one number
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    // Check for at least 2 special characters (!@#$%)
    final specialChars = RegExp(r'[!@#$%]').allMatches(value).length;
    if (specialChars < 2) {
      return 'Password must contain at least 2 special characters (!@#\$%)';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateStoreName(String? value) {
    if (_selectedRole != 'staff') return null;
    if (value == null || value.isEmpty) {
      return 'Please enter your store name';
    }
    if (value.length < 2) {
      return 'Store name must be at least 2 characters';
    }
    return null;
  }

  String? _validateStudentId(String? value) {
    if (_selectedRole != 'student') return null;
    if (value == null || value.isEmpty) {
      return 'Please enter your student ID';
    }
    // Student ID should be exactly 10 digits
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Student ID must be exactly 10 digits (e.g., 0124303092)';
    }
    return null;
  }

  Future<void> _submitRegistrationRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final storeName = _storeNameController.text.trim();
    final studentId = _studentIdController.text.trim();

    setState(() => _loading = true);

    try {
      // Check if email already has a pending request
      final existingRequest =
          await FirebaseFirestore.instance
              .collection('registrationRequests')
              .where('email', isEqualTo: email)
              .where('status', isEqualTo: 'pending')
              .get();

      if (existingRequest.docs.isNotEmpty) {
        if (!mounted) return;
        _showError(
          'A registration request for this email is already pending approval.',
        );
        return;
      }

      // Check if email already exists in users collection
      final existingUser =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .get();

      if (existingUser.docs.isNotEmpty) {
        if (!mounted) return;
        _showError('An account with this email already exists. Please login.');
        return;
      }

      // Create registration request
      final requestData = {
        'name': name,
        'email': email,
        'password': password, // Will be used by admin to create account
        'role': _selectedRole,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add store name for merchants
      if (_selectedRole == 'staff' && storeName.isNotEmpty) {
        requestData['storeName'] = storeName;
      }

      // Add student ID for students
      if (_selectedRole == 'student' && studentId.isNotEmpty) {
        requestData['studentId'] = studentId;
      }

      await FirebaseFirestore.instance
          .collection('registrationRequests')
          .add(requestData);

      if (!mounted) return;

      _showRequestSubmitted();
    } catch (e) {
      if (!mounted) return;
      debugPrint('Registration error: $e');
      _showError('Registration failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    AppModalDialog.error(
      context: context,
      title: 'Registration Failed',
      message: message,
    );
  }

  void _showRequestSubmitted() {
    final roleLabel = _selectedRole == 'student' ? 'Student' : 'Merchant';
    AppModalDialog.success(
      context: context,
      title: 'Request Submitted!',
      message:
          'Your $roleLabel registration request has been submitted and is pending admin approval. You will be notified once your account is ready.',
      primaryLabel: 'Back to Login',
      onPrimaryPressed: () {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMerchant = _selectedRole == 'staff';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),

                // Logo
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Image.network(
                    'https://res.cloudinary.com/ddg9ffo5r/image/upload/spcf_mzffy6',
                    fit: BoxFit.contain,
                    errorBuilder:
                        (context, error, stackTrace) => const Icon(
                          Icons.image,
                          size: 60,
                          color: AppColors.primary,
                        ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // App Name
                Text(
                  'Create Account',
                  style: AppTextStyles.heading1.copyWith(
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  'Choose your account type to get started',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Role Selection Tabs
                _buildRoleSelector(isDark),

                const SizedBox(height: AppSpacing.lg),

                // Full Name Field
                AppTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  prefixIcon: Icon(
                    Iconsax.user,
                    color:
                        isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: _validateName,
                ),

                const SizedBox(height: AppSpacing.md),

                // Email Field
                AppTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'yourname@gmail.com',
                  prefixIcon: Icon(
                    Iconsax.sms,
                    color:
                        isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateEmail,
                ),

                // Student ID Field (only for students)
                if (!isMerchant) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _studentIdController,
                    label: 'Student ID',
                    hint: 'e.g., 0124303092',
                    prefixIcon: Icon(
                      Iconsax.card,
                      color:
                          isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiary,
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: _validateStudentId,
                  ),
                ],

                // Store Name Field (only for merchants)
                if (isMerchant) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _storeNameController,
                    label: 'Store Name',
                    hint: 'Enter your store/business name',
                    prefixIcon: Icon(
                      Iconsax.shop,
                      color:
                          isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiary,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: _validateStoreName,
                  ),
                ],

                const SizedBox(height: AppSpacing.md),

                // Password Field
                AppTextField.password(
                  controller: _passwordController,
                  label: 'Password',
                  hint: '8-16 chars, letters, numbers, 2 special (!@#\$%)',
                  obscureText: !_showPassword,
                  onToggleObscure: () {
                    setState(() => _showPassword = !_showPassword);
                  },
                  textInputAction: TextInputAction.next,
                  validator: _validatePassword,
                ),

                const SizedBox(height: AppSpacing.md),

                // Confirm Password Field
                AppTextField.password(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  obscureText: !_showConfirmPassword,
                  onToggleObscure: () {
                    setState(
                      () => _showConfirmPassword = !_showConfirmPassword,
                    );
                  },
                  textInputAction: TextInputAction.done,
                  validator: _validateConfirmPassword,
                  onFieldSubmitted: (_) => _submitRegistrationRequest(),
                ),

                const SizedBox(height: AppSpacing.md),

                // Info notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? AppColors.info.withOpacity(0.1)
                            : AppColors.info.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.info_circle,
                        color: AppColors.info,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your registration request will be reviewed by an admin before your account is created.',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Submit Button
                AppButton(
                  label: 'Submit Registration Request',
                  onPressed: _submitRegistrationRequest,
                  isLoading: _loading,
                  isFullWidth: true,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color:
                            isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: Text(
                        'Sign In',
                        style: AppTextStyles.labelMedium.copyWith(
                          color:
                              isDark
                                  ? AppColors.primaryLight
                                  : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildRoleTab(
            label: 'Student',
            icon: Iconsax.user,
            role: 'student',
            isDark: isDark,
          ),
          const SizedBox(width: 4),
          _buildRoleTab(
            label: 'Merchant',
            icon: Iconsax.shop,
            role: 'staff',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTab({
    required String label,
    required IconData icon,
    required String role,
    required bool isDark,
  }) {
    final isSelected = _selectedRole == role;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedRole = role);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? (isDark ? AppColors.primary : AppColors.primary)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color:
                    isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
