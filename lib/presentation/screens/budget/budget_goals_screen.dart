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
  Map<String, double> _limits = {};
  bool _isEditing = false;
  bool _isLoading = false;

  static const _defaults = {
    'Food': 500.0, 'Transport': 200.0, 'Shopping': 300.0,
    'Entertainment': 150.0, 'Utilities': 100.0,
    'Healthcare': 200.0, 'Education': 250.0, 'Other': 100.0,
  };

  @override
  void initState() {
    super.initState();
    _loadGoals();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<TransactionProvider>().loadCurrentMonth());
  }

  Future<void> _loadGoals() async {
    final month = DateFormat('yyyy-MM').format(DateTime.now());
    final goals = await _repo.getByMonth(month);
    setState(() {
      _limits = goals.isEmpty
          ? Map.from(_defaults)
          : {for (final g in goals) g.category: g.limitAmount};
    });
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final month = DateFormat('yyyy-MM').format(DateTime.now());
      await _repo.replaceMonth(month, _limits);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(AppStrings.budgetUpdated),
            backgroundColor: Color(0xFF10B981)));
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: AppColors.of(context).error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _editLimit(AppColorSet c, String category, double current) {
    final ctrl = TextEditingController(text: current.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('Edit Budget — $category',
            style: TextStyle(color: c.textPrimary)),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: c.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter budget limit', prefixText: '\$ ',
            hintStyle: TextStyle(color: c.textSecondary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.cancel, style: TextStyle(color: c.textSecondary))),
          TextButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text) ?? 0;
              if (v > 0) {
                setState(() => _limits[category] = v);
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text(AppStrings.enterValidAmount)));
              }
            },
            child: Text(AppStrings.save, style: TextStyle(color: c.primary)),
          ),
        ],
      ),
    );
  }

  void _addCategory(AppColorSet c) {
    final nameCtrl   = TextEditingController();
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(AppStrings.addNewCategory,
            style: TextStyle(color: c.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameCtrl,
            style: TextStyle(color: c.textPrimary),
            decoration: InputDecoration(
              hintText: AppStrings.categoryName,
              hintStyle: TextStyle(color: c.textSecondary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: c.textPrimary),
            decoration: InputDecoration(
              hintText: AppStrings.budgetLimit, prefixText: '\$ ',
              hintStyle: TextStyle(color: c.textSecondary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.cancel, style: TextStyle(color: c.textSecondary))),
          TextButton(
            onPressed: () {
              final name   = nameCtrl.text.trim();
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (name.isNotEmpty && amount > 0) {
                setState(() => _limits[name] = amount);
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text(AppStrings.fillAllFields)));
              }
            },
            child: Text(AppStrings.add, style: TextStyle(color: c.primary)),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(AppColorSet c, String category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(AppStrings.deleteCategory,
            style: TextStyle(color: c.textPrimary)),
        content: Text('Delete "$category" category?',
            style: TextStyle(color: c.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.cancel, style: TextStyle(color: c.textSecondary))),
          TextButton(
            onPressed: () {
              setState(() => _limits.remove(category));
              Navigator.pop(ctx);
            },
            child: Text(AppStrings.delete, style: TextStyle(color: c.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c   = AppColors.of(context);
    final txP = context.watch<TransactionProvider>();

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.primary, elevation: 0,
        title: const Text(AppStrings.budgetGoals,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _monthLabel(c),
            const SizedBox(height: 24),
            _overallCard(c, txP),
            const SizedBox(height: 24),
            _categoriesList(c, txP),
            if (_isEditing) ...[
              const SizedBox(height: 24),
              _actionButtons(c),
            ],
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  Widget _monthLabel(AppColorSet c) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Icon(Icons.calendar_today, color: c.primary),
      const SizedBox(width: 12),
      Text(DateFormat('MMMM yyyy').format(DateTime.now()),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
              color: c.textPrimary)),
    ]),
  );

  Widget _overallCard(AppColorSet c, TransactionProvider txP) {
    final total   = _limits.values.fold<double>(0, (s, v) => s + v);
    final spent   = txP.totalExpenses;
    final pct     = total > 0 ? (spent / total * 100).clamp(0.0, 100.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c.primary, c.primary.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(AppStrings.overallBudget,
            style: TextStyle(fontSize: 14, color: Colors.white70)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('\$${spent.toStringAsFixed(2)} / \$${total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text('${pct.toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct / 100, minHeight: 8,
            backgroundColor: Colors.white30,
            valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 100 ? c.error : c.secondary),
          ),
        ),
      ]),
    );
  }

  Widget _categoriesList(AppColorSet c, TransactionProvider txP) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(AppStrings.categories, style: TextStyle(fontSize: 16,
            fontWeight: FontWeight.bold, color: c.textPrimary)),
        if (_isEditing)
          GestureDetector(
            onTap: () => _addCategory(c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: c.primary,
                  borderRadius: BorderRadius.circular(8)),
              child: const Row(children: [
                Icon(Icons.add, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text(AppStrings.addCategory,
                    style: TextStyle(fontSize: 12, color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
      ]),
      const SizedBox(height: 16),
      if (_limits.isEmpty)
        Center(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(AppStrings.noBudgetLimits,
              style: TextStyle(fontSize: 14,
                  color: c.textSecondary.withOpacity(0.7))),
        ))
      else
        ..._limits.entries.map((e) {
          final cat        = e.key;
          final limit      = e.value;
          final spent      = txP.spendingByCategory[cat] ?? 0.0;
          final pct        = limit > 0 ? (spent / limit * 100).clamp(0.0, 100.0) : 0.0;
          final overBudget = spent > limit;
          final color      = CategoryUtils.color(cat);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: overBudget ? c.error : c.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: color.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: Icon(CategoryUtils.icon(cat), color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(cat, style: TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w600, color: c.textPrimary)),
                    Text('Budget & Spending', style: TextStyle(fontSize: 12,
                        color: c.textSecondary.withOpacity(0.7))),
                  ]),
                ]),
                if (_isEditing)
                  Row(children: [
                    _iconBtn(Icons.edit, c.primary, c.primary.withOpacity(0.1),
                        () => _editLimit(c, cat, limit)),
                    const SizedBox(width: 8),
                    _iconBtn(Icons.delete, c.error, c.error.withOpacity(0.1),
                        () => _deleteCategory(c, cat)),
                  ]),
              ]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Limit: \$${limit.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12, color: c.textSecondary)),
                Text('Spent: \$${spent.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: overBudget ? c.error : c.textPrimary)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct / 100, minHeight: 6,
                  backgroundColor: c.textSecondary.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      overBudget ? c.error : c.secondary),
                ),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${pct.toStringAsFixed(0)}% used',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                        color: overBudget ? c.error : c.textSecondary)),
                if (overBudget)
                  Text('Over by \$${(spent - limit).toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: c.error)),
              ]),
            ]),
          );
        }),
    ],
  );

  Widget _iconBtn(IconData icon, Color color, Color bg, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 16, color: color),
      ),
    );

  Widget _actionButtons(AppColorSet c) => Column(children: [
    SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: c.secondary, foregroundColor: Colors.white,
          disabledBackgroundColor: c.secondary.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _isLoading
            ? const SizedBox(height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white)))
            : const Text(AppStrings.saveChanges,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    ),
    const SizedBox(height: 12),
    SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isLoading ? null : () => setState(() => _isEditing = false),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: c.primary), foregroundColor: c.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text(AppStrings.cancel,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    ),
  ]);
}