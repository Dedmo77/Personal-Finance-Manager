import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/app_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../providers/currency_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey                 = GlobalKey<FormState>();
  final _nameController          = TextEditingController();
  final _emailController         = TextEditingController();
  final _passwordController      = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  String _selectedCurrency = 'USD';

  @override
  void dispose() {
    _nameController.dispose(); _emailController.dispose();
    _passwordController.dispose(); _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthProvider>().register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      baseCurrency: _selectedCurrency,
    );
    // Sync CurrencyProvider base with the chosen currency
    if (mounted) {
      context.read<CurrencyProvider>().setBaseCurrency(_selectedCurrency);
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c          = AppColors.of(context);
    final currencies = context.watch<CurrencyProvider>().currencies;
    final isLoading  =
        context.watch<AuthProvider>().status == AuthStatus.loading;

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
              Text(AppStrings.createAccount,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                      color: c.textPrimary)),
              const SizedBox(height: 8),
              Text(AppStrings.registerSubtitle,
                  style: TextStyle(fontSize: 15, color: c.textSecondary)),
              const SizedBox(height: 40),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _nameController,
                      label: AppStrings.fullName, hint: AppStrings.fullNameHint,
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) {
                        if (v == null || v.isEmpty) return AppStrings.nameRequired;
                        if (v.length < 2) return AppStrings.nameTooShort;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
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
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return AppStrings.passwordRequired;
                        if (v.length < 6) return AppStrings.passwordShort;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _confirmPasswordController,
                      label: AppStrings.confirmPassword, hint: AppStrings.passwordHint,
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscureConfirm,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: c.textSecondary, size: 20),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return AppStrings.confirmPasswordRequired;
                        if (v != _passwordController.text) return AppStrings.passwordsDoNotMatch;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Currency picker
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.baseCurrency,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                                color: c.textPrimary)),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: c.border),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCurrency,
                              isExpanded: true,
                              dropdownColor: c.surface,
                              icon: Icon(Icons.keyboard_arrow_down_rounded,
                                  color: c.textSecondary),
                              style: TextStyle(fontSize: 15, color: c.textPrimary),
                              items: currencies.map((cur) => DropdownMenuItem(
                                  value: cur,
                                  child: Text(cur,
                                      style: TextStyle(color: c.textPrimary)))).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedCurrency = v);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.primary, foregroundColor: Colors.white,
                          disabledBackgroundColor: c.primary.withOpacity(0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isLoading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Text(AppStrings.register,
                                style: TextStyle(fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppStrings.alreadyHaveAccount,
                      style: TextStyle(color: c.textSecondary, fontSize: 14)),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text(AppStrings.signIn,
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