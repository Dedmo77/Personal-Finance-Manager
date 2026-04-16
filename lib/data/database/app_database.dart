import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as model;
import '../models/budget_goal.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pocketlens.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        convertedAmount REAL NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        date INTEGER NOT NULL,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE budget_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        month TEXT NOT NULL,
        limitAmount REAL NOT NULL
      )
    ''');
  }

  // ── Transactions ──────────────────────────────────────────

  Future<int> insertTransaction(model.Transaction t) async {
    final db = await database;
    return await db.insert('transactions', t.toMap());
  }

  Future<List<model.Transaction>> getTransactionsByMonth(String month) async {
    final db = await database;
    final start = DateTime.parse('$month-01').millisecondsSinceEpoch;
    final end = DateTime(
      int.parse(month.split('-')[0]),
      int.parse(month.split('-')[1]) + 1,
    ).millisecondsSinceEpoch;

    final maps = await db.query(
      'transactions',
      where: 'date >= ? AND date < ?',
      whereArgs: [start, end],
      orderBy: 'date DESC',
    );
    return maps.map((m) => model.Transaction.fromMap(m)).toList();
  }

  Future<List<model.Transaction>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((m) => model.Transaction.fromMap(m)).toList();
  }

  Future<int> updateTransaction(model.Transaction t) async {
    final db = await database;
    return await db.update(
      'transactions',
      t.toMap(),
      where: 'id = ?',
      whereArgs: [t.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ── Budget Goals ──────────────────────────────────────────

  Future<int> insertBudgetGoal(BudgetGoal goal) async {
    final db = await database;
    return await db.insert('budget_goals', goal.toMap());
  }

  Future<List<BudgetGoal>> getBudgetGoalsByMonth(String month) async {
    final db = await database;
    final maps = await db.query(
      'budget_goals',
      where: 'month = ?',
      whereArgs: [month],
    );
    return maps.map((m) => BudgetGoal.fromMap(m)).toList();
  }

  Future<int> updateBudgetGoal(BudgetGoal goal) async {
    final db = await database;
    return await db.update(
      'budget_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> deleteBudgetGoal(int id) async {
    final db = await database;
    return await db.delete('budget_goals', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}