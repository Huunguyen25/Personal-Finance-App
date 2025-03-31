import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Transaction {
  final String title;
  final String categoryId; // Changed from category to categoryId
  final double amount;
  final bool isExpense;
  final DateTime date;
  final String? note;

  Transaction({
    required this.title,
    required this.categoryId, // Changed parameter name
    required this.amount,
    required this.isExpense,
    required this.date,
    this.note,
  });

  // Add serialization methods
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'categoryId': categoryId, // Changed field name
      'amount': amount,
      'isExpense': isExpense,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  // Create a transaction from JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      title: json['title'],
      // Handle both old "category" field and new "categoryId" field for backward compatibility
      categoryId: json['categoryId'] ?? json['category'] ?? 'miscellaneous',
      amount: json['amount'].toDouble(),
      isExpense: json['isExpense'],
      date: DateTime.parse(json['date']),
      note: json['note'],
    );
  }
}

// Shared service to manage transactions across screens
class TransactionService {
  static const String _transactionsKey = 'transactions';

  // Get all transactions
  static Future<List<Transaction>> getAllTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = prefs.getString(_transactionsKey);

      if (transactionsJson != null) {
        final List<dynamic> decodedList = jsonDecode(transactionsJson);
        return decodedList.map((item) => Transaction.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error loading transactions: $e');
    }
    return [];
  }

  // Save transactions
  static Future<void> saveTransactions(List<Transaction> transactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> transactionsMap =
          transactions.map((t) => t.toJson()).toList();
      await prefs.setString(_transactionsKey, jsonEncode(transactionsMap));
    } catch (e) {
      print('Error saving transactions: $e');
    }
  }

  // Get today's transactions
  static Future<List<Transaction>> getTodayTransactions() async {
    final allTransactions = await getAllTransactions();
    final now = DateTime.now();
    return allTransactions.where((transaction) {
      return transaction.date.year == now.year &&
          transaction.date.month == now.month &&
          transaction.date.day == now.day;
    }).toList();
  }

  // Add a new transaction
  static Future<void> addTransaction(Transaction transaction) async {
    final transactions = await getAllTransactions();
    transactions.add(transaction);
    await saveTransactions(transactions);
  }
}
