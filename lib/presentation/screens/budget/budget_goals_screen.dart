import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/transaction_provider.dart';
import '../../../data/database/app_database.dart';
import '../../../data/models/budget_goal.dart';

class BudgetGoalsScreen extends StatefulWidget {
  const BudgetGoalsScreen({super.key});

  @override
  State<BudgetGoalsScreen> createState() => _BudgetGoalsScreenState();
}

class _BudgetGoalsScreenState extends State<BudgetGoalsScreen> {
  late Map<String, double> _budgetLimits;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBudgetGoals();
    // Load current month data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final month = DateFormat('yyyy-MM').format(DateTime.now());
      context.read<TransactionProvider>().loadMonth(month);
    });
  }

  Future<void> _loadBudgetGoals() async {
    final month = DateFormat('yyyy-MM').format(DateTime.now());
    final goals =
        await AppDatabase.instance.getBudgetGoalsByMonth(month);

    setState(() {
      if (goals.isEmpty) {
        // Initialize with default values if no goals exist
        _budgetLimits = {
          'Food': 500,
          'Transport': 200,
          'Shopping': 300,
          'Entertainment': 150,
          'Utilities': 100,
          'Healthcare': 200,
          'Education': 250,
          'Other': 100,
        };
      } else {
        // Load from database
        _budgetLimits = {for (var goal in goals) goal.category: goal.limitAmount};
      }
    });
  }

  Future<void> _handleSaveChanges() async {
    setState(() => _isLoading = true);

    try {
      final month = DateFormat('yyyy-MM').format(DateTime.now());

      // Delete old budget goals for this month
      final oldGoals =
          await AppDatabase.instance.getBudgetGoalsByMonth(month);
      for (var goal in oldGoals) {
        await AppDatabase.instance.deleteBudgetGoal(goal.id!);
      }

      // Save new budget goals
      for (var entry in _budgetLimits.entries) {
        final goal = BudgetGoal(
          category: entry.key,
          month: month,
          limitAmount: entry.value,
        );
        await AppDatabase.instance.insertBudgetGoal(goal);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget limits updated successfully'),
            backgroundColor: AppColors.secondary,
          ),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving changes: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _editBudgetLimit(String category, double currentAmount) {
    final controller = TextEditingController(text: currentAmount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Budget Limit - $category'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter budget limit',
            prefixText: '\$ ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newLimit = double.tryParse(controller.text) ?? 0;
              if (newLimit > 0) {
                setState(() {
                  _budgetLimits[category] = newLimit;
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addNewCategory() {
    final controller = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Category name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Budget limit',
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final categoryName = controller.text.trim();
              final amount = double.tryParse(amountController.text) ?? 0;

              if (categoryName.isNotEmpty && amount > 0) {
                setState(() {
                  _budgetLimits[categoryName] = amount;
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields with valid values'),
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete the "$category" category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _budgetLimits.remove(category);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
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
        title: const Text(
          'Budget Goals',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
              _buildMonthSelector(),
              const SizedBox(height: 24),
              _buildOverallBudgetStatus(txProvider),
              const SizedBox(height: 24),
              const Text(
                'Budget by Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
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

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.calendar_today, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            DateFormat('MMMM yyyy').format(DateTime.now()),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.primary),
            onPressed: () {
              // Add month navigation if needed
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverallBudgetStatus(TransactionProvider txProvider) {
    final totalBudget = _budgetLimits.values.fold<double>(0, (sum, v) => sum + v);
    final totalSpent = txProvider.totalExpenses;
    final percentSpent = (totalSpent / totalBudget * 100).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Budget',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${totalSpent.toStringAsFixed(2)} / \$${totalBudget.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${percentSpent.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (_isEditing)
              GestureDetector(
                onTap: _addNewCategory,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
              child: Text(
                'No budget limits set',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
              ),
            ),
          )
        else
          ..._budgetLimits.entries.map((entry) {
            final category = entry.key;
            final limit = entry.value;
            final spent = txProvider.spendingByCategory[category] ?? 0.0;
            final percentSpent = (spent / limit * 100).clamp(0, 100);
            final isOverBudget = spent > limit;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(
                  color: isOverBudget ? AppColors.error : AppColors.border,
                ),
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
                              color: _getCategoryColor(category)
                                  .withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _categoryIcon(category),
                              color: _getCategoryColor(category),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Budget & Spending',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_isEditing)
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _editBudgetLimit(category, limit),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _deleteCategory(category),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  size: 16,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Limit: \$${limit.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Spent: \$${spent.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOverBudget
                              ? AppColors.error
                              : AppColors.textPrimary,
                        ),
                      ),
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
                        isOverBudget
                            ? AppColors.error
                            : AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${percentSpent.toStringAsFixed(0)}% used',
                        style: TextStyle(
                          fontSize: 11,
                          color: isOverBudget
                              ? AppColors.error
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isOverBudget)
                        Text(
                          'Over by \$${(spent - limit).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
      ],
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
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
            ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading
                ? null
                : () => setState(() => _isEditing = false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
        return Icons.home;
      case 'healthcare':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      default:
        return Icons.more_horiz;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFFF6B6B);
      case 'transport':
        return const Color(0xFF4ECDC4);
      case 'shopping':
        return const Color(0xFFFFE66D);
      case 'entertainment':
        return const Color(0xFFA78BFA);
      case 'utilities':
        return const Color(0xFF34D399);
      case 'healthcare':
        return const Color(0xFFFF8C5A);
      case 'education':
        return const Color(0xFF60A5FA);
      default:
        return AppColors.textSecondary;
    }
  }
}

