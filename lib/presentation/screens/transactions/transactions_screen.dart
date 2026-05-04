import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/category_utils.dart';
import '../../providers/transaction_provider.dart';
import '../../../data/models/transaction.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final c   = AppColors.of(context);
    final txP = context.watch<TransactionProvider>();

    final filtered = _filter == 'all'
        ? txP.transactions
        : txP.transactions.where((t) => t.type == _filter).toList();

    final grouped = <String, List<Transaction>>{};
    for (final t in filtered) {
      final key = DateFormat('MMM dd, yyyy')
          .format(DateTime.fromMillisecondsSinceEpoch(t.date));
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.primary, elevation: 0,
        title: const Text('Transactions',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SafeArea(
        child: Column(children: [
          // Filter tabs
          Container(
            padding: const EdgeInsets.all(16),
            color: c.surface,
            child: Row(children: [
              _chip(c, 'All', 'all'),
              const SizedBox(width: 8),
              _chip(c, 'Income', 'income'),
              const SizedBox(width: 8),
              _chip(c, 'Expense', 'expense'),
            ]),
          ),
          Expanded(
            child: txP.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _emptyState(c)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: grouped.length,
                        itemBuilder: (_, i) {
                          final key = grouped.keys.elementAt(i);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(key,
                                    style: TextStyle(fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: c.textSecondary)),
                              ),
                              ...grouped[key]!.map((t) => _txTile(c, t)),
                            ],
                          );
                        },
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _chip(AppColorSet c, String label, String type) {
    final sel = _filter == type;
    return GestureDetector(
      onTap: () => setState(() => _filter = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? c.primary : c.border,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: sel ? Colors.white : c.textSecondary)),
      ),
    );
  }

  Widget _txTile(AppColorSet c, Transaction t) {
    final isExpense = t.type == 'expense';
    final color     = isExpense ? c.error : c.secondary;
    final fmt       = NumberFormat.currency(symbol: '\$');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: Icon(CategoryUtils.icon(t.category), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.description,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: c.textPrimary)),
              const SizedBox(height: 4),
              Text(t.category,
                  style: TextStyle(fontSize: 12, color: c.textSecondary)),
            ]),
          ]),
          Text(
            '${isExpense ? '-' : '+'}${fmt.format(t.convertedAmount)}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(AppColorSet c) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.receipt_long_outlined, size: 64,
          color: c.textSecondary.withOpacity(0.5)),
      const SizedBox(height: 16),
      Text('No transactions', style: TextStyle(fontSize: 16,
          fontWeight: FontWeight.w600, color: c.textSecondary)),
      const SizedBox(height: 8),
      Text('Start by adding your first transaction',
          style: TextStyle(fontSize: 12, color: c.textSecondary.withOpacity(0.7))),
    ]),
  );
}