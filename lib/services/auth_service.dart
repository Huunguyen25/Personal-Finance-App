import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart';
import '../models/user.dart';
import '../models/account.dart';

class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Check if email already exists
  Future<bool> isEmailAvailable(String email) async {
    bool exists = await _dbHelper.emailExists(email);
    return !exists;
  }

  // Register new user
  Future<int?> registerUser(User user) async {
    return await _dbHelper.insertUser(user.toMap());
  }

  // Login
  Future<User?> loginUser(String email, String password) async {
    Map<String, dynamic>? userData = await _dbHelper.getUser(email, password);
    if (userData != null) {
      User user = User.fromMap(userData);
      await saveUserSession(user.id!);
      return user;
    }
    return null;
  }

  // Get user by id
  Future<User?> getUserById(int userId) async {
    Map<String, dynamic>? userData = await _dbHelper.getUserById(userId);
    if (userData != null) {
      return User.fromMap(userData);
    }
    return null;
  }

  // Create demo accounts
  Future<List<Account>> createDemoAccounts(int userId) async {
    Random random = Random();
    List<Account> accounts = [];

    List<String> accountTypes = [
      'Checking Account',
      'Savings Account',
      'Investment Account',
      'Credit Card',
    ];

    for (String type in accountTypes) {
      double balance = 5000 + random.nextDouble() * 5000;
      String accountNumber = _generateAccountNumber();

      Account account = Account(
        userId: userId,
        accountName: type,
        accountNumber: accountNumber,
        balance: double.parse(balance.toStringAsFixed(2)),
        isDemo: true,
      );

      int id = await _dbHelper.insertAccount(account.toMap());
      account = Account(
        id: id,
        userId: userId,
        accountName: type,
        accountNumber: accountNumber,
        balance: double.parse(balance.toStringAsFixed(2)),
        isDemo: true,
      );

      accounts.add(account);
    }

    return accounts;
  }

  // Create selected demo account
  Future<Account?> createSelectedDemoAccount(
    int userId,
    String accountName,
    String accountNumber,
    double balance,
  ) async {
    Account account = Account(
      userId: userId,
      accountName: accountName,
      accountNumber: accountNumber,
      balance: balance,
      isDemo: true,
    );

    int id = await _dbHelper.insertAccount(account.toMap());
    if (id > 0) {
      return Account(
        id: id,
        userId: userId,
        accountName: accountName,
        accountNumber: accountNumber,
        balance: balance,
        isDemo: true,
      );
    }
    return null;
  }

  // Create real account with zero balance
  Future<Account?> createRealAccount(int userId) async {
    Account account = Account(
      userId: userId,
      accountName: 'My Account',
      accountNumber: _generateAccountNumber(),
      balance: 0.0,
      isDemo: false,
    );

    int id = await _dbHelper.insertAccount(account.toMap());
    if (id > 0) {
      return Account(
        id: id,
        userId: userId,
        accountName: 'My Account',
        accountNumber: account.accountNumber,
        balance: 0.0,
        isDemo: false,
      );
    }
    return null;
  }

  // Create manual account
  Future<Account?> createManualAccount(
    int userId,
    String accountName,
    String accountNumber,
    double balance,
  ) async {
    Account account = Account(
      userId: userId,
      accountName: accountName,
      accountNumber: accountNumber,
      balance: balance,
      isDemo: false,
    );

    int id = await _dbHelper.insertAccount(account.toMap());
    if (id > 0) {
      return Account(
        id: id,
        userId: userId,
        accountName: accountName,
        accountNumber: accountNumber,
        balance: balance,
        isDemo: false,
      );
    }
    return null;
  }

  // Get user accounts
  Future<List<Account>> getUserAccounts(int userId) async {
    List<Map<String, dynamic>> accountsData = await _dbHelper.getUserAccounts(
      userId,
    );
    return accountsData.map((data) => Account.fromMap(data)).toList();
  }

  String _generateAccountNumber() {
    Random random = Random();
    String accountNumber = '';
    for (int i = 0; i < 10; i++) {
      accountNumber += random.nextInt(10).toString();
    }
    return accountNumber;
  }

  // Generate random account number
  String generateAccountNumber() {
    Random random = Random();
    String accountNumber = '';
    for (int i = 0; i < 10; i++) {
      accountNumber += random.nextInt(10).toString();
    }
    return accountNumber;
  }

  // Session management - Rename this method to public (removing underscore)
  Future<void> saveUserSession(int userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId);
    await prefs.setBool('isLoggedIn', true);
  }

  Future<int?> getCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Regular logout (only clears sessions)
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Logout but preserve user data
  Future<void> preserveAndLogout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Only remove login status, but keep user ID and other data
    await prefs.setBool('isLoggedIn', false);
  }

  // Completely wipe user data and logout
  Future<void> wipeUserDataAndLogout() async {
    try {
      // Get current user ID before clearing preferences
      final userId = await getCurrentUserId();

      // Clear all shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (userId != null) {
        // Delete user accounts
        await _dbHelper.deleteUserAccounts(userId);

        // Delete user transactions (if you implement this feature later)
        await _dbHelper.deleteUserTransactions(userId);

        // Delete budget data
        await _dbHelper.deleteUserBudgets(userId);

        // Finally delete the user itself
        await _dbHelper.deleteUser(userId);
      }
    } catch (e) {
      print('Error during data wipe: $e');
      rethrow;
    }
  }
}
