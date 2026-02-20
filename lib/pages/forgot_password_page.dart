// lib/pages/forgot_password_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../widgets/app_modal_dialog.dart';

/// Forgot Password page - sends password reset email via Firebase
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
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

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _emailSent = true;
        _loading = false;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(_getFirebaseErrorMessage(e.code));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Something went wrong. Please try again.');
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return 'Failed to send reset email. Please try again.';
    }
  }

  void _showError(String message) {
    AppModalDialog.error(context: context, title: 'Error', message: message);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Iconsax.arrow_left,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child:
              _emailSent ? _buildSuccessView(isDark) : _buildFormView(isDark),
        ),
      ),
    );
  }

  Widget _buildFormView(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),

          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primaryLight : AppColors.primary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Iconsax.lock_1,
              size: 32,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Title
          Text(
            'Forgot Password?',
            style: AppTextStyles.heading1.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            "No worries! Enter your school email and we'll send you a link to reset your password.",
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
                  isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: _validateEmail,
            onSubmitted: (_) => _sendResetEmail(),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Send Button
          AppButton(
            label: 'Send Reset Link',
            onPressed: _sendResetEmail,
            isLoading: _loading,
            isFullWidth: true,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Back to login
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Iconsax.arrow_left_2,
                    size: 16,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Back to Login',
                    style: AppTextStyles.labelMedium.copyWith(
                      color:
                          isDark ? AppColors.primaryLight : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.xxl * 2),

        // Success Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Iconsax.tick_circle,
            size: 40,
            color: AppColors.success,
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Title
        Text(
          'Email Sent!',
          style: AppTextStyles.heading1.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        Text(
          'We sent a password reset link to',
          style: AppTextStyles.bodyMedium.copyWith(
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.xs),

        Text(
          _emailController.text.trim(),
          style: AppTextStyles.labelLarge.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: AppSpacing.xxl),

        // Instructions
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color:
                isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              _buildInstructionItem(isDark, '1', 'Check your email inbox'),
              const SizedBox(height: AppSpacing.sm),
              _buildInstructionItem(isDark, '2', 'Click the reset link'),
              const SizedBox(height: AppSpacing.sm),
              _buildInstructionItem(isDark, '3', 'Create a new password'),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xxl),

        // Back to Login Button
        AppButton(
          label: 'Back to Login',
          onPressed: () => Navigator.pop(context),
          isFullWidth: true,
        ),

        const SizedBox(height: AppSpacing.md),

        // Didn't receive email
        GestureDetector(
          onTap: () {
            setState(() => _emailSent = false);
          },
          child: Text(
            "Didn't receive the email? Try again",
            style: AppTextStyles.labelMedium.copyWith(
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionItem(bool isDark, String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isDark ? AppColors.primaryLight : AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
