import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BudgetService {
  static const String _budgetMonthKey = 'budget_month';
  static const String _hasBudgetKey = 'has_budget';
  static const String _budgetIncomeKey = 'budget_income';
  static const String _budgetPaychecksKey = 'budget_paychecks';
  static const String _budgetBillsKey = 'budget_bills';

  // Get the current month's budget data
  static Future<Map<String, dynamic>> getCurrentBudgetData() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> budgetData = {
      'month': prefs.getString(_budgetMonthKey) ?? '',
      'hasBudget': prefs.getBool(_hasBudgetKey) ?? false,
      'income': prefs.getDouble(_budgetIncomeKey) ?? 0.0,
      'paychecks': [],
      'bills': [],
      'totalPaychecks': 0.0,
      'totalBills': 0.0,
    };

    final paycheckData = prefs.getString(_budgetPaychecksKey);
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

    final billsData = prefs.getString(_budgetBillsKey);
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
}
