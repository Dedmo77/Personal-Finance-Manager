import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/category_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../../data/models/transaction.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<TransactionProvider>().loadCurrentMonth());
  }

  @override
  Widget build(BuildContext context) {
    final c        = AppColors.of(context);
    final auth     = context.watch<AuthProvider>();
    final txP      = context.watch<TransactionProvider>();

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: txP.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => txP.reload(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(c, auth),
                      const SizedBox(height: 24),
                      _buildBalanceCard(c, txP),
                      const SizedBox(height: 24),
                      _buildIncomeExpenseRow(c, txP),
                      const SizedBox(height: 24),
                      _buildQuickActions(c),
                      const SizedBox(height: 24),
                      _buildRecentTransactions(c, txP),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNav(c),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-transaction'),
        backgroundColor: c.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTopBar(AppColorSet c, AuthProvider auth) {
    final h = DateTime.now().hour;
    final greeting = h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$greeting,', style: TextStyle(fontSize: 14, color: c.textSecondary)),
          Text(auth.userName.isEmpty ? 'User' : auth.userName,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.textPrimary)),
        ]),
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: c.primaryLight,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.person_outline_rounded, color: c.primary, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(AppColorSet c, TransactionProvider txP) {
    final fmt = NumberFormat.currency(symbol: '\$');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(AppStrings.totalBalance,
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        Text(fmt.format(txP.balance),
            style: const TextStyle(color: Colors.white, fontSize: 36,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Text(DateFormat('MMMM yyyy').format(DateTime.now()),
            style: const TextStyle(color: Colors.white60, fontSize: 13)),
      ]),
    );
  }

  Widget _buildIncomeExpenseRow(AppColorSet c, TransactionProvider txP) {
    final fmt = NumberFormat.currency(symbol: '\$');
    return Row(children: [
      Expanded(child: _summaryCard(c,
          label: AppStrings.income,
          amount: fmt.format(txP.totalIncome),
          icon: Icons.arrow_downward_rounded, color: c.secondary)),
      const SizedBox(width: 16),
      Expanded(child: _summaryCard(c,
          label: AppStrings.expenses,
          amount: fmt.format(txP.totalExpenses),
          icon: Icons.arrow_upward_rounded, color: c.error)),
    ]);
  }

  Widget _summaryCard(AppColorSet c,
      {required String label, required String amount,
       required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border)),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 12, color: c.textSecondary)),
          Text(amount, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
              color: c.textPrimary)),
        ]),
      ]),
    );
  }

  Widget _buildQuickActions(AppColorSet c) {
    final actions = [
      {'label': 'Add',          'icon': Icons.add_circle_outline_rounded, 'route': '/add-transaction'},
      {'label': 'Transactions', 'icon': Icons.receipt_long_outlined,      'route': '/transactions'},
      {'label': 'Budget',       'icon': Icons.pie_chart_outline_rounded,  'route': '/budget'},
      {'label': 'Reports',      'icon': Icons.bar_chart_rounded,          'route': '/reports'},
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(AppStrings.quickActions,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary)),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions.map((a) => GestureDetector(
          onTap: () => context.push(a['route'] as String),
          child: Column(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: c.primaryLight,
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(a['icon'] as IconData, color: c.primary, size: 24),
            ),
            const SizedBox(height: 6),
            Text(a['label'] as String,
                style: TextStyle(fontSize: 12, color: c.textSecondary)),
          ]),
        )).toList(),
      ),
    ]);
  }

  Widget _buildRecentTransactions(AppColorSet c, TransactionProvider txP) {
    final recent = txP.recentTransactions;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(AppStrings.recentTransactions,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: c.textPrimary)),
        GestureDetector(
          onTap: () => context.push('/transactions'),
          child: Text(AppStrings.seeAll,
              style: TextStyle(fontSize: 14, color: c.primary,
                  fontWeight: FontWeight.w500)),
        ),
      ]),
      const SizedBox(height: 12),
      recent.isEmpty
          ? _emptyState(c)
          : Column(children: recent.map((t) => _txTile(c, t)).toList()),
    ]);
  }

  Widget _txTile(AppColorSet c, Transaction t) {
    final isExpense = t.type == 'expense';
    final color     = isExpense ? c.error : c.secondary;
    final sign      = isExpense ? '-' : '+';
    final date      = DateTime.fromMillisecondsSinceEpoch(t.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border)),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(CategoryUtils.icon(t.category), color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.description,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                  color: c.textPrimary)),
          Text('${t.category} · ${DateFormat('MMM d').format(date)}',
              style: TextStyle(fontSize: 12, color: c.textSecondary)),
        ])),
        Text('$sign\$${t.convertedAmount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  Widget _emptyState(AppColorSet c) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 40),
    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border)),
    child: Column(children: [
      Icon(Icons.receipt_long_outlined, size: 48, color: c.textSecondary),
      const SizedBox(height: 12),
      Text(AppStrings.noTransactions,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
              color: c.textSecondary)),
      const SizedBox(height: 4),
      Text(AppStrings.noTransactionsHint,
          style: TextStyle(fontSize: 13, color: c.textSecondary)),
    ]),
  );

  Widget _buildBottomNav(AppColorSet c) => NavigationBar(
    backgroundColor: c.surface,
    selectedIndex: 0,
    onDestinationSelected: (i) {
      switch (i) {
        case 0: context.go('/dashboard'); break;
        case 1: context.go('/transactions'); break;
        case 2: context.go('/budget'); break;
        case 3: context.go('/reports'); break;
        case 4: context.go('/profile'); break;
      }
    },
    destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Transactions'),
      NavigationDestination(icon: Icon(Icons.pie_chart_outline_rounded),
          selectedIcon: Icon(Icons.pie_chart_rounded), label: 'Budget'),
      NavigationDestination(icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
      NavigationDestination(icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
    ],
  );
}