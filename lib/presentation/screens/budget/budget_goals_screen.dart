import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/category_utils.dart';
import '../../providers/transaction_provider.dart';
import '../../../data/repositories/budget_repository.dart';

class BudgetGoalsScreen extends StatefulWidget {
  const BudgetGoalsScreen({super.key});

  @override
  State<BudgetGoalsScreen> createState() => _BudgetGoalsScreenState();
}

class _BudgetGoalsScreenState extends State<BudgetGoalsScreen> {
  final _repo = BudgetRepository();

  Map<String, double> _budgetLimits = {};
  bool _isEditing = false;
  bool _isLoading = false;

  static const Map<String, double> _defaultLimits = {
    'Food': 500,
    'Transport': 200,
    'Shopping': 300,
    'Entertainment': 150,
    'Utilities': 100,
    'Healthcare': 200,
    'Education': 250,
    'Other': 100,
  };

  @override
  void initState() {
    super.initState();
    _loadBudgetGoals();
    // TransactionProvider already owns the current month; just ensure data
    // is loaded (no-op if it was already loaded by DashboardScreen).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadCurrentMonth();
    });
  }

  Future<void> _loadBudgetGoals() async {
    final month = DateFormat('yyyy-MM').format(DateTime.now());
    final goals = await _repo.getByMonth(month);

    setState(() {
      _budgetLimits = goals.isEmpty
          ? Map.from(_defaultLimits)
          : {for (final g in goals) g.category: g.limitAmount};
    });
  }

  Future<void> _handleSaveChanges() async {
    setState(() => _isLoading = true);

    try {
      final month = DateFormat('yyyy-MM').format(DateTime.now());
      await _repo.replaceMonth(month, _budgetLimits);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(AppStrings.budgetUpdated),
              backgroundColor: AppColors.secondary),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving changes: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _editBudgetLimit(String category, double currentAmount) {
    final controller =
        TextEditingController(text: currentAmount.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Budget — $category'),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Enter budget limit',
            prefixText: '\$ ',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.cancel)),
          TextButton(
            onPressed: () {
              final newLimit = double.tryParse(controller.text) ?? 0;
              if (newLimit > 0) {
                setState(() => _budgetLimits[category] = newLimit);
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(AppStrings.enterValidAmount)),
                );
              }
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }

  void _addNewCategory() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.addNewCategory),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: AppStrings.categoryName,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: AppStrings.budgetLimit,
                prefixText: '\$ ',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.cancel)),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              final amount = double.tryParse(amountController.text) ?? 0;
              if (name.isNotEmpty && amount > 0) {
                setState(() => _budgetLimits[name] = amount);
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(AppStrings.fillAllFields)),
                );
              }
            },
            child: const Text(AppStrings.add),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(String category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteCategory),
        content:
            Text('Are you sure you want to delete the "$category" category?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.cancel)),
          TextButton(
            onPressed: () {
              setState(() => _budgetLimits.remove(category));
              Navigator.pop(ctx);
            },
            child: const Text(AppStrings.delete,
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(AppStrings.budgetGoals,
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMonthLabel(),
              const SizedBox(height: 24),
              _buildOverallBudgetStatus(txProvider),
              const SizedBox(height: 24),
              const Text(AppStrings.budgetByCategory,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              _buildCategoriesList(txProvider),
              if (_isEditing) ...[
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthLabel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            DateFormat('MMMM yyyy').format(DateTime.now()),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallBudgetStatus(TransactionProvider txProvider) {
    final totalBudget =
        _budgetLimits.values.fold<double>(0, (sum, v) => sum + v);
    final totalSpent = txProvider.totalExpenses;
    final percentSpent =
        totalBudget > 0 ? (totalSpent / totalBudget * 100).clamp(0, 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(AppStrings.overallBudget,
              style: TextStyle(fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${totalSpent.toStringAsFixed(2)} / \$${totalBudget.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                '${percentSpent.toStringAsFixed(0)}%',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentSpent / 100,
              minHeight: 8,
              backgroundColor: Colors.white30,
              valueColor: AlwaysStoppedAnimation<Color>(
                percentSpent > 100 ? AppColors.error : AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(TransactionProvider txProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(AppStrings.categories,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            if (_isEditing)
              GestureDetector(
                onTap: _addNewCategory,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(AppStrings.addCategory,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_budgetLimits.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(AppStrings.noBudgetLimits,
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary.withOpacity(0.7))),
            ),
          )
        else
          ..._budgetLimits.entries.map((entry) {
            final category = entry.key;
            final limit = entry.value;
            final spent =
                txProvider.spendingByCategory[category] ?? 0.0;
            final percentSpent =
                limit > 0 ? (spent / limit * 100).clamp(0, 100) : 0.0;
            final isOverBudget = spent > limit;
            final color = CategoryUtils.color(category);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(
                    color: isOverBudget
                        ? AppColors.error
                        : AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(CategoryUtils.icon(category),
                                color: color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(category,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                              Text('Budget & Spending',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary
                                          .withOpacity(0.7))),
                            ],
                          ),
                        ],
                      ),
                      if (_isEditing)
                        Row(
                          children: [
                            _iconAction(
                              icon: Icons.edit,
                              color: AppColors.primary,
                              bgColor: AppColors.primary.withOpacity(0.1),
                              onTap: () =>
                                  _editBudgetLimit(category, limit),
                            ),
                            const SizedBox(width: 8),
                            _iconAction(
                              icon: Icons.delete,
                              color: AppColors.error,
                              bgColor: AppColors.error.withOpacity(0.1),
                              onTap: () => _deleteCategory(category),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Limit: \$${limit.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                      Text('Spent: \$${spent.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isOverBudget
                                  ? AppColors.error
                                  : AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: percentSpent / 100,
                      minHeight: 6,
                      backgroundColor:
                          AppColors.textSecondary.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOverBudget ? AppColors.error : AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${percentSpent.toStringAsFixed(0)}% used',
                          style: TextStyle(
                              fontSize: 11,
                              color: isOverBudget
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w500)),
                      if (isOverBudget)
                        Text(
                          'Over by \$${(spent - limit).toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.error,
                              fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _iconAction({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: bgColor, borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSaveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              disabledBackgroundColor:
                  AppColors.secondary.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : const Text(AppStrings.saveChanges,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed:
                _isLoading ? null : () => setState(() => _isEditing = false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(AppStrings.cancel,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
          ),
        ),
      ],
    );
  }
}