import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../services/auth_service.dart'; // Import AuthService to get current user

class BudgetDatabase {
  static final BudgetDatabase instance = BudgetDatabase._init();
  static Database? _database;

  BudgetDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('budget.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add userId column to all tables
      await db.execute(
        'ALTER TABLE budget_income ADD COLUMN userId INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE paychecks ADD COLUMN userId INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE planned_bills ADD COLUMN userId INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  Future _createDB(Database db, int version) async {
    // Income table with userId
    await db.execute('''
      CREATE TABLE budget_income (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        month TEXT NOT NULL,
        amount REAL NOT NULL
      )
    ''');

    // Paychecks table with userId
    await db.execute('''
      CREATE TABLE paychecks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        month TEXT NOT NULL,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // Bills table with userId
    await db.execute('''
      CREATE TABLE planned_bills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        month TEXT NOT NULL,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        due_date TEXT NOT NULL
      )
    ''');
  }

  // Get the current userId
  Future<int?> _getCurrentUserId() async {
    return await AuthService().getCurrentUserId();
  }

  // Income operations
  Future<int> insertIncome(String month, double amount) async {
    final db = await instance.database;
    final userId = await _getCurrentUserId() ?? 0;

    // First try to update existing income for this month and user
    int updated = await db.update(
      'budget_income',
      {'amount': amount},
      where: 'month = ? AND userId = ?',
      whereArgs: [month, userId],
    );

    // If no records were updated, insert a new one
    if (updated == 0) {
      return await db.insert('budget_income', {
        'userId': userId,
        'month': month,
        'amount': amount,
      });
    }
    return updated;
  }

  Future<double> getIncome(String month) async {
    final db = await instance.database;
    final userId = await _getCurrentUserId() ?? 0;

    final results = await db.query(
      'budget_income',
      where: 'month = ? AND userId = ?',
      whereArgs: [month, userId],
    );

    if (results.isNotEmpty) {
      return results.first['amount'] as double;
    }
    return 0.0;
  }

  // Paycheck operations
  Future<int> insertPaycheck(
    String month,
    String name,
    double amount,
    DateTime date,
  ) async {
    final db = await instance.database;
    final userId = await _getCurrentUserId() ?? 0;

    return await db.insert('paychecks', {
      'userId': userId,
      'month': month,
      'name': name,
      'amount': amount,
      'date': date.toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPaychecks(String month) async {
    final db = await instance.database;
    final userId = await _getCurrentUserId() ?? 0;

    final results = await db.query(
      'paychecks',
      where: 'month = ? AND userId = ?',
      whereArgs: [month, userId],
    );

    return results.map((row) {
      return {
        'id': row['id'],
        'name': row['name'],
        'amount': row['amount'],
        'date': DateTime.parse(row['date'] as String),
      };
    }).toList();
  }

  Future<int> deletePaycheck(int id) async {
    final db = await instance.database;
    final userId = await _getCurrentUserId() ?? 0;

    return await db.delete(
      'paychecks',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  // Planned bills operations
  Future<int> insertBill(
    String month,
    String name,
    double amount,
    DateTime dueDate,
  ) async {
    final db = await instance.database;
    final userId = await _getCurrentUserId() ?? 0;

    return await db.insert('planned_bills', {
      'userId': userId,
      'month': month,
      'name': name,
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPlannedBills(String month) async {
    final db = await instance.database;
    final userId = await _getCurrentUserId() ?? 0;

    final results = await db.query(
      'planned_bills',
      where: 'month = ? AND userId = ?',
      whereArgs: [month, userId],
    );

    return results.map((row) {
      return {
        'id': row['id'],
        'name': row['name'],
        'amount': row['amount'],
        'dueDate': DateTime.parse(row['due_date'] as String),
      };
    }).toList();
  }

  Future<int> deleteBill(int id) async {
    final db = await instance.database;
    final userId = await _getCurrentUserId() ?? 0;

    return await db.delete(
      'planned_bills',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  // Check if budget exists for a month
  Future<bool> hasBudget(String month) async {
    final db = await instance.database;
    final userId = await _getCurrentUserId() ?? 0;

    final results = await db.query(
      'budget_income',
      where: 'month = ? AND userId = ?',
      whereArgs: [month, userId],
    );

    return results.isNotEmpty;
  }

  // Cleanup old data
  Future<void> cleanupOldData(String currentMonth) async {
    final db = await instance.database;
    final userId = await _getCurrentUserId() ?? 0;

    // Only delete old data for the current user
    await db.delete(
      'budget_income',
      where: 'month != ? AND userId = ?',
      whereArgs: [currentMonth, userId],
    );
    await db.delete(
      'paychecks',
      where: 'month != ? AND userId = ?',
      whereArgs: [currentMonth, userId],
    );
    await db.delete(
      'planned_bills',
      where: 'month != ? AND userId = ?',
      whereArgs: [currentMonth, userId],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
