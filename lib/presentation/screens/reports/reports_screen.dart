import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/category_utils.dart';
import '../../providers/transaction_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c   = AppColors.of(context);
    final txP = context.watch<TransactionProvider>();

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.primary, elevation: 0,
        title: const Text(AppStrings.reports,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _summaryCards(c, txP),
            const SizedBox(height: 24),
            _barChart(c, txP),
            const SizedBox(height: 24),
            _categoryBreakdown(c, txP),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  Widget _summaryCards(AppColorSet c, TransactionProvider txP) => Row(children: [
    Expanded(child: _card(c, label: AppStrings.income,
        amount: txP.totalIncome, icon: Icons.trending_up, color: c.secondary)),
    const SizedBox(width: 12),
    Expanded(child: _card(c, label: AppStrings.expenses,
        amount: txP.totalExpenses, icon: Icons.trending_down, color: c.error)),
  ]);

  Widget _card(AppColorSet c,
      {required String label, required double amount,
       required IconData icon, required Color color}) =>
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(fontSize: 12, color: c.textSecondary,
              fontWeight: FontWeight.w600)),
          Icon(icon, color: color, size: 20),
        ]),
        const SizedBox(height: 8),
        Text('\$${amount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ]),
    );

  Widget _barChart(AppColorSet c, TransactionProvider txP) {
    final maxY = [txP.totalIncome, txP.totalExpenses]
            .reduce((a, b) => a > b ? a : b) * 1.2;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppStrings.incomeVsExpenses,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                color: c.textPrimary)),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY == 0 ? 100 : maxY,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Text(
                  [AppStrings.income, AppStrings.expenses][v.toInt()],
                  style: TextStyle(color: c.textSecondary,
                      fontWeight: FontWeight.bold, fontSize: 12)),
              )),
              leftTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 40,
                getTitlesWidget: (v, _) => Text('\$${v.toInt()}',
                    style: TextStyle(color: c.textSecondary, fontSize: 10)),
              )),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              BarChartGroupData(x: 0, barRods: [BarChartRodData(
                toY: txP.totalIncome, color: c.secondary, width: 40,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)))]),
              BarChartGroupData(x: 1, barRods: [BarChartRodData(
                toY: txP.totalExpenses, color: c.error, width: 40,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)))]),
            ],
          )),
        ),
      ]),
    );
  }

  Widget _categoryBreakdown(AppColorSet c, TransactionProvider txP) {
    final spending = txP.spendingByCategory;
    if (spending.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(AppStrings.noExpenseData,
            style: TextStyle(color: c.textSecondary))),
      );
    }
    final total = spending.values.fold<double>(0, (s, v) => s + v);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surface, border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppStrings.spendingByCategory,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                color: c.textPrimary)),
        const SizedBox(height: 16),
        ...spending.entries.map((e) {
          final cat    = e.key;
          final amount = e.value;
          final pct    = amount / total * 100;
          final color  = CategoryUtils.color(cat);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: color.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: Icon(CategoryUtils.icon(cat), color: color, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Text(cat, style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600, color: c.textPrimary)),
                ]),
                Text('\$${amount.toStringAsFixed(2)} (${pct.toStringAsFixed(1)}%)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                        color: c.textSecondary)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct / 100, minHeight: 6,
                  backgroundColor: c.border,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}