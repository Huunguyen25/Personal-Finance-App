import '../db/database_helper.dart';
import '../models/transaction.dart';
import '../services/auth_service.dart';

class TransactionService {
  static final DatabaseHelper _dbHelper = DatabaseHelper();
  static final AuthService _authService = AuthService();

  // Get all transactions for the current user
  static Future<List<Transaction>> getAllTransactions() async {
    try {
      // Get current user ID
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get transactions from database
      final transactionsData = await _dbHelper.getUserTransactions(userId);
      return transactionsData.map((data) => Transaction.fromMap(data)).toList();
    } catch (e) {
      print('Error retrieving transactions: $e');
      return [];
    }
  }

  // Save a transaction
  static Future<bool> saveTransaction(Transaction transaction) async {
    try {
      await _dbHelper.insertTransaction(transaction.toMap());
      return true;
    } catch (e) {
      print('Error saving transaction: $e');
      return false;
    }
  }

  // Update a transaction
  static Future<bool> updateTransaction(Transaction transaction) async {
    try {
      await _dbHelper.updateTransaction(transaction.toMap());
      return true;
    } catch (e) {
      print('Error updating transaction: $e');
      return false;
    }
  }

  // Delete a transaction
  static Future<bool> deleteTransaction(String transactionId) async {
    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      await _dbHelper.deleteTransaction(transactionId, userId);
      return true;
    } catch (e) {
      print('Error deleting transaction: $e');
      return false;
    }
  }

  // Get transactions for a specific date
  static Future<List<Transaction>> getTransactionsForDate(DateTime date) async {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) return [];

    final transactions = await getAllTransactions();
    return transactions.where((transaction) {
      return transaction.date.year == date.year &&
          transaction.date.month == date.month &&
          transaction.date.day == date.day &&
          transaction.userId == userId; // Filter by userId
    }).toList();
  }
}
