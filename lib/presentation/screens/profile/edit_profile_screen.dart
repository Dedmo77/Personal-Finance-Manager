import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/app_text_field.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _currentPwController  = TextEditingController();
  final _newPwController      = TextEditingController();
  final _confirmPwController  = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _isLoading      = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController  = TextEditingController(text: auth.userName);
    _emailController = TextEditingController(text: auth.userEmail);
  }

  @override
  void dispose() {
    _nameController.dispose(); _emailController.dispose();
    _currentPwController.dispose(); _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final err = await context.read<AuthProvider>().updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      currentPassword: _currentPwController.text.isEmpty
          ? null : _currentPwController.text,
      newPassword: _newPwController.text.isEmpty
          ? null : _newPwController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err),
          backgroundColor: AppColors.of(context).error));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(AppStrings.profileUpdated),
          backgroundColor: Color(0xFF10B981)));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.primary, elevation: 0,
        title: const Text(AppStrings.editProfile,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _section(c,
                title: AppStrings.basicInformation,
                child: Column(children: [
                  AppTextField(
                    controller: _nameController,
                    label: AppStrings.fullNameLabel, hint: AppStrings.fullNameFieldHint,
                    prefixIcon: Icons.person,
                    validator: (v) {
                      if (v == null || v.isEmpty) return AppStrings.nameRequired;
                      if (v.length < 2) return AppStrings.nameTooShort;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _emailController,
                    label: AppStrings.emailLabel, hint: AppStrings.emailFieldHint,
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return AppStrings.emailRequired;
                      if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                              .hasMatch(v))
                        return AppStrings.emailInvalid;
                      return null;
                    },
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              _section(c,
                title: AppStrings.changePassword,
                subtitle: AppStrings.changePasswordSubtitle,
                child: Column(children: [
                  AppTextField(
                    controller: _currentPwController,
                    label: AppStrings.currentPassword,
                    hint: AppStrings.currentPasswordHint,
                    prefixIcon: Icons.lock,
                    obscureText: _obscureCurrent,
                    suffixIcon: _visBtn(_obscureCurrent, c,
                        () => setState(() => _obscureCurrent = !_obscureCurrent)),
                    validator: (v) {
                      if (_newPwController.text.isNotEmpty &&
                          (v == null || v.isEmpty))
                        return AppStrings.currentPasswordRequired;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _newPwController,
                    label: AppStrings.newPassword, hint: AppStrings.newPasswordHint,
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscureNew,
                    suffixIcon: _visBtn(_obscureNew, c,
                        () => setState(() => _obscureNew = !_obscureNew)),
                    validator: (v) {
                      if (v != null && v.isNotEmpty && v.length < 6)
                        return AppStrings.passwordShort;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _confirmPwController,
                    label: AppStrings.confirmNewPassword,
                    hint: AppStrings.confirmNewPasswordHint,
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscureConfirm,
                    suffixIcon: _visBtn(_obscureConfirm, c,
                        () => setState(() => _obscureConfirm = !_obscureConfirm)),
                    validator: (v) {
                      if (_newPwController.text.isNotEmpty) {
                        if (v == null || v.isEmpty) return AppStrings.confirmPasswordRequired;
                        if (v != _newPwController.text) return AppStrings.passwordsDoNotMatch;
                      }
                      return null;
                    },
                  ),
                ]),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    disabledBackgroundColor: c.primary.withOpacity(0.5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Text(AppStrings.saveChanges,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: c.primary),
                    foregroundColor: c.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(AppStrings.cancel,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _section(AppColorSet c,
      {required String title, String? subtitle, required Widget child}) =>
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
            color: c.textPrimary)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: c.textSecondary)),
        ],
        const SizedBox(height: 16),
        child,
      ]),
    );

  Widget _visBtn(bool obscure, AppColorSet c, VoidCallback onTap) => IconButton(
    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
        color: c.textSecondary, size: 20),
    onPressed: onTap,
  );
}