import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});
  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey              = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController      = TextEditingController();
  final _noteController        = TextEditingController();

  String   _type             = 'expense';
  String   _selectedCategory = 'Food';
  DateTime _selectedDate     = DateTime.now();
  String   _selectedCurrency = 'USD';
  bool     _isLoading        = false;

  static const _categories = [
    'Food', 'Transport', 'Shopping', 'Entertainment',
    'Utilities', 'Healthcare', 'Education', 'Salary', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    // Default the transaction currency to the user's base currency.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final base = context.read<AuthProvider>().baseCurrency;
      setState(() => _selectedCurrency = base);
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final amount       = double.parse(_amountController.text);
      final baseCurrency = context.read<AuthProvider>().baseCurrency;

      // Convert to user's base currency using live rates.
      final convertedAmount = await context
          .read<CurrencyProvider>()
          .convertToBase(amount, _selectedCurrency);

      final transaction = Transaction(
        description:     _descriptionController.text.trim(),
        amount:          amount,
        currency:        _selectedCurrency,
        convertedAmount: convertedAmount,
        category:        _selectedCategory,
        type:            _type,
        date:            _selectedDate.millisecondsSinceEpoch,
        note:            _noteController.text.trim(),
      );

      await context.read<TransactionProvider>().addTransaction(transaction);

      if (mounted) {
        final c = AppColors.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            '${_type == 'income' ? 'Income' : 'Expense'} added'
            '${_selectedCurrency != baseCurrency
                ? ' (converted to $baseCurrency)' : ''}',
          ),
          backgroundColor: c.secondary,
        ));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.of(context).error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final c         = AppColors.of(context);
    final currencies = context.watch<CurrencyProvider>().currencies;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.primary,
        elevation: 0,
        title: const Text('Add Transaction',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _typeSelector(c),
                const SizedBox(height: 24),

                _section(c, title: 'Transaction Details', child: Column(children: [
                  _textField(c,
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Enter transaction description',
                    prefixIcon: Icons.description,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 16),
                  _textField(c,
                    controller: _amountController,
                    label: 'Amount',
                    hint: '0.00',
                    prefixIcon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Amount is required';
                      if (double.tryParse(v) == null) return 'Enter a valid amount';
                      if (double.parse(v) <= 0) return 'Amount must be greater than 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _dropdownField(c,
                    label: 'Currency',
                    value: _selectedCurrency,
                    items: currencies,
                    onChanged: (v) => setState(() => _selectedCurrency = v!),
                  ),
                  // Live rate hint
                  if (context.watch<CurrencyProvider>().status ==
                      CurrencyStatus.loaded &&
                      _selectedCurrency !=
                          context.watch<AuthProvider>().baseCurrency)
                    _rateHint(c),
                ])),
                const SizedBox(height: 24),

                _section(c, title: 'Category & Date', child: Column(children: [
                  _dropdownField(c,
                    label: 'Category',
                    value: _selectedCategory,
                    items: _categories,
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                  const SizedBox(height: 16),
                  _datePicker(c),
                ])),
                const SizedBox(height: 24),

                _section(c, title: 'Additional Notes', child: _textField(c,
                  controller: _noteController,
                  label: 'Notes',
                  hint: 'Add optional notes',
                  prefixIcon: Icons.note,
                  maxLines: 3,
                )),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: c.primary.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white)))
                        : const Text('Add Transaction',
                            style: TextStyle(fontSize: 16,
                                fontWeight: FontWeight.bold)),
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
                    child: const Text('Cancel',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _typeSelector(AppColorSet c) => Container(
    decoration: BoxDecoration(
      color: c.surface,
      border: Border.all(color: c.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(children: [
      Expanded(child: _typeBtn(c, label: 'Expense', value: 'expense',
          icon: Icons.trending_down, color: c.error)),
      Expanded(child: _typeBtn(c, label: 'Income', value: 'income',
          icon: Icons.trending_up, color: c.secondary)),
    ]),
  );

  Widget _typeBtn(AppColorSet c,
      {required String label, required String value,
       required IconData icon, required Color color}) {
    final selected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold,
            color: selected ? color : c.textSecondary,
          )),
        ]),
      ),
    );
  }

  Widget _section(AppColorSet c,
      {required String title, required Widget child}) =>
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
            color: c.textPrimary)),
        const SizedBox(height: 12),
        child,
      ]),
    );

  Widget _textField(AppColorSet c, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: c.textPrimary)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(color: c.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: c.textSecondary),
          prefixIcon: Icon(prefixIcon, color: c.primary, size: 20),
          filled: true,
          fillColor: c.primaryLight,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.primary, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.error)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.error, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ]);

  Widget _dropdownField(AppColorSet c, {
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    // Guard: if value isn't in the list yet (e.g. rates still loading), show first item
    final safeValue = items.contains(value) ? value : (items.isNotEmpty ? items.first : value);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: c.textPrimary)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: c.primaryLight,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          underline: const SizedBox(),
          dropdownColor: c.surface,
          style: TextStyle(color: c.textPrimary, fontSize: 14),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.textSecondary),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item, style: TextStyle(color: c.textPrimary)),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    ]);
  }

  Widget _datePicker(AppColorSet c) => GestureDetector(
    onTap: _selectDate,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.primaryLight,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(Icons.calendar_today, color: c.primary),
          const SizedBox(width: 12),
          Text(DateFormat('MMM dd, yyyy').format(_selectedDate),
              style: TextStyle(fontSize: 14, color: c.textPrimary)),
        ]),
        Icon(Icons.chevron_right, color: c.textSecondary),
      ]),
    ),
  );

  Widget _rateHint(AppColorSet c) {
    final currencyP  = context.read<CurrencyProvider>();
    final base       = context.read<AuthProvider>().baseCurrency;
    final amount     = double.tryParse(_amountController.text) ?? 0;
    // Use synchronous rate approximation for the hint display
    final rates      = currencyP.rates;            // base-relative rates
    // rates are fetched with baseCurrency as base, so 1 base = rates[other]
    // We want: amount in _selectedCurrency → base
    // We previously fetched with toCurrency=base, so rates[_selectedCurrency] = how many
    // selectedCurrency per 1 base  →  converted = amount / rates[_selectedCurrency]
    final rate       = rates[_selectedCurrency];
    final approx     = (rate != null && rate > 0) ? amount / rate : null;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(children: [
        Icon(Icons.info_outline, size: 14, color: c.textSecondary),
        const SizedBox(width: 6),
        Text(
          approx != null
              ? '≈ ${approx.toStringAsFixed(2)} $base'
              : 'Rate unavailable — will use original amount',
          style: TextStyle(fontSize: 12, color: c.textSecondary),
        ),
      ]),
    );
  }
}