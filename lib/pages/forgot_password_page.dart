// lib/pages/forgot_password_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../widgets/app_modal_dialog.dart';

/// Forgot Password page - submits request for admin approval
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _loading = false;
  bool _requestSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _reasonController.dispose();
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

  Future<void> _submitPasswordRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final email = _emailController.text.trim();

      // Submit password request for admin approval
      // Note: User lookup is done by admin when processing the request
      await FirebaseFirestore.instance.collection('passwordRequests').add({
        'email': email,
        'reason': _reasonController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _requestSent = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      debugPrint('Password request error: $e');
      _showError('Something went wrong. Please try again.');
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
              _requestSent ? _buildSuccessView(isDark) : _buildFormView(isDark),
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
            "Enter your school email and reason for reset. An admin will review your request and send you a reset link.",
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
            textInputAction: TextInputAction.next,
            validator: _validateEmail,
          ),

          const SizedBox(height: AppSpacing.md),

          // Reason Field
          AppTextField(
            controller: _reasonController,
            label: 'Reason (optional)',
            hint: 'e.g., Forgot my password, Account recovery...',
            prefixIcon: Icon(
              Iconsax.message_text,
              color:
                  isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            ),
            maxLines: 2,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submitPasswordRequest(),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Send Button
          AppButton(
            label: 'Submit Request',
            onPressed: _submitPasswordRequest,
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
          'Request Submitted!',
          style: AppTextStyles.heading1.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        Text(
          'Your password reset request has been submitted for',
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
              _buildInstructionItem(
                isDark,
                '1',
                'Admin will review your request',
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildInstructionItem(
                isDark,
                '2',
                'Once approved, check your email',
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildInstructionItem(
                isDark,
                '3',
                'Click the reset link to create new password',
              ),
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

        // Submit another request
        GestureDetector(
          onTap: () {
            setState(() => _requestSent = false);
            _emailController.clear();
            _reasonController.clear();
          },
          child: Text(
            'Submit another request',
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
