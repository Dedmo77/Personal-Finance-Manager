import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/app_text_field.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey          = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose(); _passwordController.dispose(); super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<AuthProvider>().login(
        _emailController.text.trim(), _passwordController.text);
    if (ok && mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final c    = AppColors.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: c.primary,
                    borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(height: 24),
              Text(AppStrings.welcomeBack,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                      color: c.textPrimary)),
              const SizedBox(height: 8),
              Text(AppStrings.loginSubtitle,
                  style: TextStyle(fontSize: 15, color: c.textSecondary)),
              const SizedBox(height: 40),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (auth.status == AuthStatus.error) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: c.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: c.error.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          Icon(Icons.error_outline, color: c.error, size: 18),
                          const SizedBox(width: 8),
                          Text(auth.errorMessage,
                              style: TextStyle(color: c.error, fontSize: 14)),
                        ]),
                      ),
                      const SizedBox(height: 16),
                    ],
                    AppTextField(
                      controller: _emailController,
                      label: AppStrings.email, hint: AppStrings.emailHint,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return AppStrings.emailRequired;
                        if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v))
                          return AppStrings.emailInvalid;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _passwordController,
                      label: AppStrings.password, hint: AppStrings.passwordHint,
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: c.textSecondary, size: 20),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return AppStrings.passwordRequired;
                        if (v.length < 6) return AppStrings.passwordShort;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: Text(AppStrings.forgotPassword,
                            style: TextStyle(color: c.primary, fontSize: 14,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton(
                        onPressed: auth.status == AuthStatus.loading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.primary, foregroundColor: Colors.white,
                          disabledBackgroundColor: c.primary.withOpacity(0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: auth.status == AuthStatus.loading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Text(AppStrings.login,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppStrings.noAccount,
                      style: TextStyle(color: c.textSecondary, fontSize: 14)),
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: Text(AppStrings.signUp,
                        style: TextStyle(color: c.primary, fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}