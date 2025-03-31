import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'finance_manager.db');
    return await openDatabase(path, version: 1, onCreate: _createDb);
  }

  Future _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        phone TEXT,
        firstName TEXT,
        lastName TEXT,
        dateOfBirth TEXT,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        accountName TEXT NOT NULL,
        accountNumber TEXT NOT NULL,
        balance REAL NOT NULL,
        isDemo INTEGER NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');
  }

  // User operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUser(String email, String password) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<bool> emailExists(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }

  // Get user by id
  Future<Map<String, dynamic>?> getUserById(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // Account operations
  Future<int> insertAccount(Map<String, dynamic> account) async {
    Database db = await database;
    return await db.insert('accounts', account);
  }

  Future<List<Map<String, dynamic>>> getUserAccounts(int userId) async {
    Database db = await database;
    return await db.query('accounts', where: 'userId = ?', whereArgs: [userId]);
  }

  // Delete all accounts for a user
  Future<int> deleteUserAccounts(int userId) async {
    final db = await database;
    return await db.delete(
      'accounts',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // Delete all transactions for a user
  Future<int> deleteUserTransactions(int userId) async {
    final db = await database;
    // If you have a transactions table, uncomment this
    // return await db.delete(
    //   'transactions',
    //   where: 'userId = ?',
    //   whereArgs: [userId],
    // );

    // Return 0 if no transactions table yet
    return 0;
  }

  // Delete all budget data for a user
  Future<int> deleteUserBudgets(int userId) async {
    final db = await database;
    // If you have a budgets table, uncomment this
    // return await db.delete(
    //   'budgets',
    //   where: 'userId = ?',
    //   whereArgs: [userId],
    // );

    // Return 0 if no budgets table yet
    return 0;
  }

  // Delete a user
  Future<int> deleteUser(int userId) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }
}
