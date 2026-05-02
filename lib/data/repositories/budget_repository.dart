import '../database/app_database.dart';
import '../models/budget_goal.dart';

class BudgetRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<BudgetGoal>> getByMonth(String month) =>
      _db.getBudgetGoalsByMonth(month);

  Future<int> insert(BudgetGoal goal) => _db.insertBudgetGoal(goal);

  Future<int> update(BudgetGoal goal) => _db.updateBudgetGoal(goal);

  Future<int> delete(int id) => _db.deleteBudgetGoal(id);

  /// Replaces all goals for [month] with the given [goals] map.
  Future<void> replaceMonth(
      String month, Map<String, double> goals) async {
    final existing = await getByMonth(month);
    for (final g in existing) {
      await delete(g.id!);
    }
    for (final entry in goals.entries) {
      await insert(BudgetGoal(
        category: entry.key,
        month: month,
        limitAmount: entry.value,
      ));
    }
  }
}