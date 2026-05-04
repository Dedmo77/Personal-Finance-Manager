import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.logoutConfirmTitle),
        content: const Text(AppStrings.logoutConfirmMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (mounted) context.go('/login');
            },
            child: Text(AppStrings.logout,
                style: TextStyle(color: AppColors.of(context).error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c            = AppColors.of(context);
    final auth         = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [
            _header(c),
            _profileCard(c, auth),
            _settingsCard(c, auth, currencyProvider),
            _prefsCard(c, themeProvider),
            _dangerZone(c),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  Widget _header(AppColorSet c) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    decoration: BoxDecoration(
      color: c.primary,
      borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text(AppStrings.profile,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
              color: Colors.white)),
      const SizedBox(height: 4),
      Text(AppStrings.profileSubtitle,
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
    ]),
  );

  Widget _profileCard(AppColorSet c, AuthProvider auth) => Container(
    margin: const EdgeInsets.all(20),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: c.primaryLight, shape: BoxShape.circle),
        child: Icon(Icons.person, size: 40, color: c.primary),
      ),
      const SizedBox(height: 16),
      Text(auth.userName.isNotEmpty ? auth.userName : 'User',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
              color: c.textPrimary)),
      const SizedBox(height: 8),
      Text(auth.userEmail, style: TextStyle(fontSize: 14, color: c.textSecondary)),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => context.push('/edit-profile'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: c.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(AppStrings.editProfile, style: TextStyle(color: c.primary)),
        ),
      ),
    ]),
  );

  Widget _settingsCard(AppColorSet c, AuthProvider auth,
      CurrencyProvider currencyP) =>
    Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppStrings.settings,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                color: c.textPrimary)),
        const SizedBox(height: 16),
        _settingTile(c,
          icon: Icons.attach_money,
          label: AppStrings.baseCurrency,
          value: auth.baseCurrency,
          onTap: () => _showCurrencyPicker(c, auth, currencyP),
        ),
        Divider(color: c.border),
        _settingTile(c,
          icon: Icons.verified_user,
          label: AppStrings.accountType,
          value: AppStrings.free,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.premiumComingSoon))),
        ),
        Divider(color: c.border),
        _settingTile(c,
          icon: Icons.calendar_today,
          label: AppStrings.memberSince,
          value: AppStrings.april2025,
          onTap: () {},
          isSelectable: false,
        ),
      ]),
    );

  Widget _prefsCard(AppColorSet c, ThemeProvider themeP) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(AppStrings.preferences,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
              color: c.textPrimary)),
      const SizedBox(height: 16),
      _toggleTile(c,
        icon: Icons.notifications, label: AppStrings.notifications,
        value: _notificationsEnabled,
        onChanged: (v) => setState(() => _notificationsEnabled = v),
      ),
      Divider(color: c.border),
      _toggleTile(c,
        icon: Icons.dark_mode, label: AppStrings.darkMode,
        value: themeP.isDarkMode,
        onChanged: (v) => themeP.setDarkMode(v),
      ),
    ]),
  );

  Widget _dangerZone(AppColorSet c) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: c.error.withOpacity(0.05),
      border: Border.all(color: c.error.withOpacity(0.2)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
          color: c.textPrimary)),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _handleLogout,
          style: ElevatedButton.styleFrom(
            backgroundColor: c.error,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.logout, size: 18), SizedBox(width: 8),
            Text(AppStrings.logout),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.deleteAccountComingSoon))),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: c.error),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.delete, size: 18, color: c.error), const SizedBox(width: 8),
            Text(AppStrings.deleteAccount, style: TextStyle(color: c.error)),
          ]),
        ),
      ),
    ]),
  );

  Widget _settingTile(AppColorSet c, {
    required IconData icon, required String label,
    required String value, required VoidCallback onTap,
    bool isSelectable = true,
  }) => GestureDetector(
    onTap: isSelectable ? onTap : null,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(icon, color: c.primary, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
              color: c.textPrimary)),
        ]),
        Row(children: [
          Text(value, style: TextStyle(fontSize: 14, color: c.textSecondary)),
          if (isSelectable)
            Icon(Icons.chevron_right, color: c.textSecondary, size: 20),
        ]),
      ]),
    ),
  );

  Widget _toggleTile(AppColorSet c, {
    required IconData icon, required String label,
    required bool value, required ValueChanged<bool> onChanged,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        Icon(icon, color: c.primary, size: 20),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
            color: c.textPrimary)),
      ]),
      Switch(value: value, onChanged: onChanged,
          activeColor: c.primary, activeTrackColor: c.primaryLight),
    ]),
  );

  void _showCurrencyPicker(AppColorSet c, AuthProvider auth,
      CurrencyProvider currencyP) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Select Base Currency',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: c.textPrimary)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: currencyP.currencies.length,
            itemBuilder: (_, i) {
              final cur = currencyP.currencies[i];
              final isSel = auth.baseCurrency == cur;
              return ListTile(
                title: Text(cur, style: TextStyle(color: c.textPrimary)),
                trailing: isSel
                    ? Icon(Icons.check, color: c.primary) : null,
                onTap: () {
                  auth.setBaseCurrency(cur);
                  currencyP.setBaseCurrency(cur);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}