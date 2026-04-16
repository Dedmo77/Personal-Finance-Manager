import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final month = DateFormat('yyyy-MM').format(DateTime.now());
      context.read<TransactionProvider>().loadMonth(month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final txProvider = context.watch<TransactionProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: txProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => txProvider.loadMonth(txProvider.currentMonth),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(auth),
                      const SizedBox(height: 24),
                      _buildBalanceCard(txProvider),
                      const SizedBox(height: 24),
                      _buildIncomeExpenseRow(txProvider),
                      const SizedBox(height: 24),
                      _buildQuickActions(context),
                      const SizedBox(height: 24),
                      _buildRecentTransactions(txProvider),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-transaction'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTopBar(AuthProvider auth) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting,',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              auth.userName.isEmpty ? 'User' : auth.userName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(TransactionProvider txProvider) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(txProvider.balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            DateFormat('MMMM yyyy').format(DateTime.now()),
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseRow(TransactionProvider txProvider) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            label: 'Income',
            amount: currencyFormat.format(txProvider.totalIncome),
            icon: Icons.arrow_downward_rounded,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            label: 'Expenses',
            amount: currencyFormat.format(txProvider.totalExpenses),
            icon: Icons.arrow_upward_rounded,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'label': 'Add', 'icon': Icons.add_circle_outline_rounded, 'route': '/add-transaction'},
      {'label': 'Transactions', 'icon': Icons.receipt_long_outlined, 'route': '/transactions'},
      {'label': 'Budget', 'icon': Icons.pie_chart_outline_rounded, 'route': '/budget'},
      {'label': 'Reports', 'icon': Icons.bar_chart_rounded, 'route': '/reports'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: actions.map((action) {
            return GestureDetector(
              onTap: () => context.push(action['route'] as String),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      action['icon'] as IconData,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    action['label'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(TransactionProvider txProvider) {
    final recent = txProvider.recentTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent transactions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/transactions'),
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        recent.isEmpty
            ? _buildEmptyState()
            : Column(
                children: recent
                    .map((t) => _buildTransactionTile(t))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildTransactionTile(Transaction t) {
    final isExpense = t.type == 'expense';
    final color = isExpense ? AppColors.error : AppColors.secondary;
    final sign = isExpense ? '-' : '+';
    final date = DateTime.fromMillisecondsSinceEpoch(t.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _categoryIcon(t.category),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${t.category} · ${DateFormat('MMM d').format(date)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$sign\$${t.convertedAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: const [
          Icon(Icons.receipt_long_outlined,
              size: 48, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap + to add your first transaction',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return NavigationBar(
      backgroundColor: AppColors.surface,
      selectedIndex: 0,
      onDestinationSelected: (index) {
        switch (index) {
          case 0: context.go('/dashboard'); break;
          case 1: context.go('/transactions'); break;
          case 2: context.go('/budget'); break;
          case 3: context.go('/reports'); break;
          case 4: context.go('/profile'); break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: 'Transactions',
        ),
        NavigationDestination(
          icon: Icon(Icons.pie_chart_outline_rounded),
          selectedIcon: Icon(Icons.pie_chart_rounded),
          label: 'Budget',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart_rounded),
          label: 'Reports',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food': return Icons.restaurant_outlined;
      case 'transport': return Icons.directions_car_outlined;
      case 'shopping': return Icons.shopping_bag_outlined;
      case 'health': return Icons.favorite_outline_rounded;
      case 'rent': return Icons.home_outlined;
      case 'entertainment': return Icons.movie_outlined;
      case 'salary': return Icons.work_outline_rounded;
      case 'utilities': return Icons.bolt_outlined;
      default: return Icons.attach_money_rounded;
    }
  }
}