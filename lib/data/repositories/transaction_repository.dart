import '../database/app_database.dart';
import '../models/transaction.dart';

class TransactionRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<int> addTransaction(Transaction t) => _db.insertTransaction(t);
  Future<List<Transaction>> getByMonth(String month) =>
      _db.getTransactionsByMonth(month);
  Future<List<Transaction>> getAll() => _db.getAllTransactions();
  Future<int> update(Transaction t) => _db.updateTransaction(t);
  Future<int> delete(int id) => _db.deleteTransaction(id);

  Future<Map<String, double>> getSpendingByCategory(String month) async {
    final transactions = await getByMonth(month);
    final Map<String, double> result = {};
    for (final t in transactions) {
      if (t.type == 'expense') {
        result[t.category] = (result[t.category] ?? 0) + t.convertedAmount;
      }
    }
    return result;
  }

Future<double> getTotalIncome(String month) async {
  final transactions = await getByMonth(month);
  return transactions
      .where((t) => t.type == 'income')
      .fold<double>(0.0, (sum, t) => sum + t.convertedAmount);
}

Future<double> getTotalExpenses(String month) async {
  final transactions = await getByMonth(month);
  return transactions
      .where((t) => t.type == 'expense')
      .fold<double>(0.0, (sum, t) => sum + t.convertedAmount);
}
}
