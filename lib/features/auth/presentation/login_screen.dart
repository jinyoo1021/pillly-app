import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/primary_text_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref.read(authNotifierProvider.notifier).signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    // Retry up to 5 times waiting for auth state
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;

      final authState = ref.read(authNotifierProvider);
      if (authState.hasError) {
        _showError(
          authState.error.toString().contains('Invalid login')
              ? 'Email or password is incorrect.'
              : authState.error.toString(),
        );
        return;
      }
      if (authState.value != null) {
        context.go(AppRoutes.home);
        return;
      }
    }
  }

  Future<void> _onGoogleLogin() async {
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
  }

  Future<void> _onAppleLogin() async {
    await ref.read(authNotifierProvider.notifier).signInWithApple();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.missed,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Header
                const Text(
                  'Welcome back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to continue managing\nyour medications.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 40),

                // Email field
                PrimaryTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  controller: _emailController,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_passwordFocus);
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email.';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Password field
                PrimaryTextField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _onLogin(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Login button
                ElevatedButton(
                  onPressed: isLoading ? null : _onLogin,
                  child: isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Sign in'),
                ),

                const SizedBox(height: 20),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.grey200)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.grey200)),
                  ],
                ),

                const SizedBox(height: 20),

                // Google login
                _SocialButton(
                  label: 'Continue with Google',
                  iconPath: '🌐',
                  onPressed: isLoading ? null : _onGoogleLogin,
                ),

                const SizedBox(height: 12),

                // Apple login
                _SocialButton(
                  label: 'Continue with Apple',
                  iconPath: '🍎',
                  onPressed: isLoading ? null : _onAppleLogin,
                ),

                const SizedBox(height: 32),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.register),
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.iconPath,
    this.onPressed,
  });

  final String label;
  final String iconPath;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(iconPath, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }
}