import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/transaction_service.dart';
import '../services/auth_service.dart';

class BudgetService {
  static const String _budgetMonthKey = 'budget_month';
  static const String _hasBudgetKey = 'has_budget';
  static const String _budgetIncomeKey = 'budget_income';
  static const String _budgetPaychecksKey = 'budget_paychecks';
  static const String _budgetBillsKey = 'budget_bills';

  // Get the current month's budget data
  static Future<Map<String, dynamic>> getCurrentBudgetData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await AuthService().getCurrentUserId();
    final userIdString = userId?.toString() ?? '0';

    // Use userId in key names for user-specific data
    final Map<String, dynamic> budgetData = {
      'month': prefs.getString('${_budgetMonthKey}_$userIdString') ?? '',
      'hasBudget': prefs.getBool('${_hasBudgetKey}_$userIdString') ?? false,
      'income': prefs.getDouble('${_budgetIncomeKey}_$userIdString') ?? 0.0,
      'paychecks': [],
      'bills': [],
      'totalPaychecks': 0.0,
      'totalBills': 0.0,
    };

    final paycheckData = prefs.getString(
      '${_budgetPaychecksKey}_$userIdString',
    );
    if (paycheckData != null) {
      final List<dynamic> decodedPaychecks = jsonDecode(paycheckData);
      final List<Map<String, dynamic>> paychecks =
          decodedPaychecks.map<Map<String, dynamic>>((item) {
            return {
              'name': item['name'],
              'amount': item['amount'],
              'date': DateTime.parse(item['date']),
            };
          }).toList();

      budgetData['paychecks'] = paychecks;
      budgetData['totalPaychecks'] = paychecks.fold(
        0.0,
        (sum, paycheck) => sum + (paycheck['amount'] as double),
      );
    }

    final billsData = prefs.getString('${_budgetBillsKey}_$userIdString');
    if (billsData != null) {
      final List<dynamic> decodedBills = jsonDecode(billsData);
      final List<Map<String, dynamic>> bills =
          decodedBills.map<Map<String, dynamic>>((item) {
            return {
              'name': item['name'],
              'amount': item['amount'],
              'dueDate': DateTime.parse(item['dueDate']),
            };
          }).toList();

      budgetData['bills'] = bills;
      budgetData['totalBills'] = bills.fold(
        0.0,
        (sum, bill) => sum + (bill['amount'] as double),
      );
    }

    return budgetData;
  }

  // Get today's transactions (using our SQLite-based TransactionService)
  static Future<List<dynamic>> getTodayTransactions() async {
    try {
      final now = DateTime.now();
      final userId = await AuthService().getCurrentUserId();
      if (userId == null) return [];

      final allTransactions = await TransactionService.getAllTransactions();

      return allTransactions.where((transaction) {
        return transaction.date.year == now.year &&
            transaction.date.month == now.month &&
            transaction.date.day == now.day &&
            transaction.userId == userId; // Filter by userId
      }).toList();
    } catch (e) {
      print('Error loading today\'s transactions: $e');
      return [];
    }
  }
}
