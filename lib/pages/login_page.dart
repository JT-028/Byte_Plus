import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final _captchaController = TextEditingController();

  bool _showPassword = false;
  bool _loading = false;

  // Login security state
  int _failedAttempts = 0;
  int _lockoutCount = 0;
  DateTime? _lockoutEndTime;
  Timer? _lockoutTimer;
  bool _requiresCaptcha = false;
  int _captchaNum1 = 0;
  int _captchaNum2 = 0;
  String _captchaOperator = '+';
  int _captchaAnswer = 0;

  // Lockout durations in minutes
  static const List<int> _lockoutDurations = [1, 3, 5];
  static const int _maxAttemptsBeforeLockout = 3;
  static const int _lockoutsBeforeCaptcha = 3;

  @override
  void initState() {
    super.initState();
    _loadSecurityState();
  }

  Future<void> _loadSecurityState() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutEnd = prefs.getInt('lockoutEndTime');
    final lockouts = prefs.getInt('lockoutCount') ?? 0;
    final attempts = prefs.getInt('failedAttempts') ?? 0;

    setState(() {
      _lockoutCount = lockouts;
      _failedAttempts = attempts;
      _requiresCaptcha = lockouts >= _lockoutsBeforeCaptcha;

      if (lockoutEnd != null) {
        final endTime = DateTime.fromMillisecondsSinceEpoch(lockoutEnd);
        if (endTime.isAfter(DateTime.now())) {
          _lockoutEndTime = endTime;
          _startLockoutTimer();
        } else {
          // Lockout expired, clear it
          prefs.remove('lockoutEndTime');
        }
      }
    });

    if (_requiresCaptcha) {
      _generateCaptcha();
    }
  }

  Future<void> _saveSecurityState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('failedAttempts', _failedAttempts);
    await prefs.setInt('lockoutCount', _lockoutCount);
    if (_lockoutEndTime != null) {
      await prefs.setInt(
        'lockoutEndTime',
        _lockoutEndTime!.millisecondsSinceEpoch,
      );
    } else {
      await prefs.remove('lockoutEndTime');
    }
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_lockoutEndTime != null && DateTime.now().isAfter(_lockoutEndTime!)) {
        setState(() {
          _lockoutEndTime = null;
        });
        _lockoutTimer?.cancel();
      } else {
        setState(() {}); // Refresh UI to update countdown
      }
    });
  }

  void _generateCaptcha() {
    final random = Random();
    _captchaNum1 = random.nextInt(10) + 1;
    _captchaNum2 = random.nextInt(10) + 1;
    final operators = ['+', '-', 'x'];
    _captchaOperator = operators[random.nextInt(operators.length)];

    switch (_captchaOperator) {
      case '+':
        _captchaAnswer = _captchaNum1 + _captchaNum2;
        break;
      case '-':
        // Ensure positive result
        if (_captchaNum1 < _captchaNum2) {
          final temp = _captchaNum1;
          _captchaNum1 = _captchaNum2;
          _captchaNum2 = temp;
        }
        _captchaAnswer = _captchaNum1 - _captchaNum2;
        break;
      case 'x':
        _captchaAnswer = _captchaNum1 * _captchaNum2;
        break;
    }
    _captchaController.clear();
  }

  void _handleFailedLogin() async {
    _failedAttempts++;

    if (_failedAttempts >= _maxAttemptsBeforeLockout) {
      // Trigger lockout
      final lockoutIndex = _lockoutCount.clamp(0, _lockoutDurations.length - 1);
      final lockoutMinutes = _lockoutDurations[lockoutIndex];

      _lockoutEndTime = DateTime.now().add(Duration(minutes: lockoutMinutes));
      _lockoutCount++;
      _failedAttempts = 0;

      // Enable captcha after 3 lockouts
      if (_lockoutCount >= _lockoutsBeforeCaptcha) {
        _requiresCaptcha = true;
        _generateCaptcha();
      }

      _startLockoutTimer();
    }

    await _saveSecurityState();
    setState(() {});
  }

  void _resetSecurityOnSuccess() async {
    _failedAttempts = 0;
    _lockoutCount = 0;
    _lockoutEndTime = null;
    _requiresCaptcha = false;
    _lockoutTimer?.cancel();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('failedAttempts');
    await prefs.remove('lockoutCount');
    await prefs.remove('lockoutEndTime');
  }

  String _formatRemainingTime() {
    if (_lockoutEndTime == null) return '';
    final diff = _lockoutEndTime!.difference(DateTime.now());
    if (diff.isNegative) return '';
    final minutes = diff.inMinutes;
    final seconds = diff.inSeconds % 60;
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  bool _isLockedOut() {
    return _lockoutEndTime != null && DateTime.now().isBefore(_lockoutEndTime!);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!value.endsWith('@gmail.com')) {
      return 'Please use your Gmail address (@gmail.com)';
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
    // Check if locked out
    if (_isLockedOut()) {
      _showError(
        'Too many failed attempts. Please wait ${_formatRemainingTime()} before trying again.',
      );
      return;
    }

    // Validate captcha if required
    if (_requiresCaptcha) {
      final userAnswer = int.tryParse(_captchaController.text.trim());
      if (userAnswer != _captchaAnswer) {
        _showError('Incorrect captcha answer. Please try again.');
        _generateCaptcha();
        setState(() {});
        return;
      }
    }

    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    setState(() => _loading = true);

    try {
      final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check Firestore document for user data
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCred.user!.uid)
              .get();

      final userData = userDoc.data() ?? {};
      final firestoreEmailVerified = userData['emailVerified'] == true;
      final userStatus = userData['status'] as String? ?? 'active';

      // Check if email is verified via Firebase Auth
      if (!userCred.user!.emailVerified) {
        // Email not verified - sign out and prompt verification
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;
        setState(() => _loading = false);

        _showEmailVerificationDialog(email);
        return;
      }

      // Email is verified - update Firestore if needed
      if (!firestoreEmailVerified || userStatus == 'pending_verification') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCred.user!.uid)
            .update({
              'emailVerified': true,
              'status': 'active',
              'emailVerifiedAt': FieldValue.serverTimestamp(),
            });
      }

      // Reset security state on successful login
      _resetSecurityOnSuccess();

      // Navigate to Splash which checks auth and routes to appropriate shell
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SplashPage()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _handleFailedLogin();
      if (_requiresCaptcha) {
        _generateCaptcha();
      }
      _showError(_getFirebaseErrorMessage(e.code));
    } catch (e) {
      if (!mounted) return;
      _handleFailedLogin();
      if (_requiresCaptcha) {
        _generateCaptcha();
      }
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

  void _showEmailVerificationDialog(String email) {
    showDialog(
      context: context,
      builder: (context) {
        bool resending = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Iconsax.sms_notification,
                    color: Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text('Email Not Verified'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please verify your email before logging in. Check your inbox for the verification link.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Email: $email',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed:
                      resending
                          ? null
                          : () async {
                            setDialogState(() => resending = true);
                            try {
                              final callable = FirebaseFunctions.instance
                                  .httpsCallable('resendVerificationEmail');
                              await callable.call({'email': email});

                              if (context.mounted) {
                                Navigator.pop(context);
                                AppModalDialog.success(
                                  context: this.context,
                                  title: 'Email Sent',
                                  message:
                                      'Verification email sent to $email. Please check your inbox.',
                                );
                              }
                            } catch (e) {
                              setDialogState(() => resending = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().contains('already-exists')
                                          ? 'Email is already verified. Try logging in again.'
                                          : 'Failed to send email. Please try again.',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                  icon:
                      resending
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Iconsax.send_1, size: 18),
                  label: Text(resending ? 'Sending...' : 'Resend Email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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

                // Lockout Warning
                if (_isLockedOut()) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.timer,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Too many failed attempts',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Try again in ${_formatRemainingTime()}',
                                style: TextStyle(
                                  color: AppColors.error.withValues(alpha: 0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Captcha
                if (_requiresCaptcha && !_isLockedOut()) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isDark
                                ? AppColors.borderDark
                                : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Iconsax.security_safe,
                              color:
                                  isDark
                                      ? AppColors.primaryLight
                                      : AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Security Verification',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                _generateCaptcha();
                                setState(() {});
                              },
                              child: Icon(
                                Iconsax.refresh,
                                color:
                                    isDark
                                        ? AppColors.primaryLight
                                        : AppColors.primary,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? AppColors.backgroundDark
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_captchaNum1 $_captchaOperator $_captchaNum2 = ?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark
                                          ? AppColors.primaryLight
                                          : AppColors.primary,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _captchaController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Answer',
                                  hintStyle: TextStyle(
                                    color:
                                        isDark
                                            ? AppColors.textTertiaryDark
                                            : AppColors.textTertiary,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  filled: true,
                                  fillColor:
                                      isDark
                                          ? AppColors.backgroundDark
                                          : Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),

                // Sign In Button
                AppButton(
                  label: _isLockedOut() ? 'Locked Out' : 'Sign In',
                  onPressed: _isLockedOut() ? null : _signIn,
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

