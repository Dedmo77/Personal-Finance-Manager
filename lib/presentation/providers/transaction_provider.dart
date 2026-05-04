import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _repo = TransactionRepository();

  List<Transaction> _transactions    = [];
  Map<String, double> _spendingByCategory = {};
  double _totalIncome   = 0;
  double _totalExpenses = 0;
  bool   _isLoading     = false;
  String _currentMonth  = DateFormat('yyyy-MM').format(DateTime.now());

  List<Transaction>   get transactions        => _transactions;
  Map<String, double> get spendingByCategory  => _spendingByCategory;
  double get totalIncome   => _totalIncome;
  double get totalExpenses => _totalExpenses;
  double get balance       => _totalIncome - _totalExpenses;
  bool   get isLoading     => _isLoading;
  String get currentMonth  => _currentMonth;
  List<Transaction> get recentTransactions => _transactions.take(5).toList();

  Future<void> loadCurrentMonth() => loadMonth(_currentMonth);

  Future<void> loadMonth(String month) async {
    _currentMonth = month;
    _isLoading    = true;
    notifyListeners();
    _transactions        = await _repo.getByMonth(month);
    _spendingByCategory  = await _repo.getSpendingByCategory(month);
    _totalIncome         = await _repo.getTotalIncome(month);
    _totalExpenses       = await _repo.getTotalExpenses(month);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> reload() => loadMonth(_currentMonth);

  Future<void> addTransaction(Transaction t) async {
    await _repo.addTransaction(t); await reload();
  }
  Future<void> updateTransaction(Transaction t) async {
    await _repo.update(t); await reload();
  }
  Future<void> deleteTransaction(int id) async {
    await _repo.delete(id); await reload();
  }
}