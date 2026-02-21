import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../widgets/app_modal_dialog.dart';
import '../pages/register_page.dart';
import 'forgot_password_page.dart';
import 'splash_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showPassword = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!value.endsWith('@canteen.spcf.co')) {
      return 'Please use your school email (@canteen.spcf.co)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Navigate to Splash which checks auth and routes to appropriate shell
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SplashPage()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(_getFirebaseErrorMessage(e.code));
    } catch (e) {
      if (!mounted) return;
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Incorrect email or password. Please try again.';
    }
  }

  void _showError(String message) {
    AppModalDialog.error(
      context: context,
      title: 'Login Failed',
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                const SizedBox(height: 60),

                // Logo
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Image.network(
                    'https://res.cloudinary.com/ddg9ffo5r/image/upload/spcf_mzffy6',
                    fit: BoxFit.contain,
                    errorBuilder:
                        (context, error, stackTrace) => const Icon(
                          Icons.image,
                          size: 80,
                          color: AppColors.primary,
                        ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // App Name
                Text(
                  'Byte Plus',
                  style: AppTextStyles.heading1.copyWith(
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  'Sign in to continue',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Email Field
                AppTextField(
                  controller: _emailController,
                  label: 'School Email',
                  hint: 'yourname@canteen.spcf.co',
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

                const SizedBox(height: AppSpacing.md),

                // Password Field
                AppTextField.password(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  obscureText: !_showPassword,
                  onToggleObscure: () {
                    setState(() => _showPassword = !_showPassword);
                  },
                  textInputAction: TextInputAction.done,
                  validator: _validatePassword,
                  onFieldSubmitted: (_) => _signIn(),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Forgot your password?',
                      style: AppTextStyles.labelMedium.copyWith(
                        color:
                            isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Sign In Button
                AppButton(
                  label: 'Sign In',
                  onPressed: _signIn,
                  isLoading: _loading,
                  isFullWidth: true,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Create Account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTextStyles.bodyMedium.copyWith(
                        color:
                            isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        );
                      },
                      child: Text(
                        'Create Account',
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
}
