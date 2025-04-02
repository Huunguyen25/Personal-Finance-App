import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction.dart';
import '../models/transaction_categories.dart';
import '../services/transaction_service.dart';
import '../database/budget_database.dart';
import '../services/auth_service.dart'; // Add this import for getting the current user

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool _isLoading = true;
  List<Transaction> _monthTransactions = [];
  List<Transaction> _allTransactions = [];
  DateTime _selectedMonth = DateTime.now();
  final Map<String, double> _expensesByCategory = {};
  final Map<String, double> _incomeByCategory = {};
  final Map<String, Color> _categoryColors = {};
  double _totalExpenses = 0;
  double _totalIncome = 0;
  double _budgetedIncome = 0;
  double _budgetedPaychecks = 0;
  bool _hasBudget = false;
  int? _userId; // Add userId field

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _assignColorsToCategories();
  }

  // Load current user and then load data
  Future<void> _loadCurrentUser() async {
    final userId = await AuthService().getCurrentUserId();
    setState(() {
      _userId = userId;
    });
    _loadData();
  }

  void _assignColorsToCategories() {
    final allCategories = Categories.getAllCategories();
    for (var category in allCategories) {
      final hue =
          (category.id.codeUnits.fold<int>(0, (a, b) => a + b) % 360)
              .toDouble();
      _categoryColors[category.id] =
          HSLColor.fromAHSL(1.0, hue, 0.7, 0.5).toColor();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Only load data if we have a valid user ID
      if (_userId != null) {
        // Load both transaction data and budget data
        await Future.wait([
          _loadTransactionsForMonth(),
          _loadBudgetData(),
          _loadTransactions(),
        ]);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading data: $e');
    }
  }

  Future<void> _loadTransactionsForMonth() async {
    try {
      if (_userId == null) return;

      final allTransactions = await TransactionService.getAllTransactions();

      final filteredTransactions =
          allTransactions.where((transaction) {
            return transaction.date.year == _selectedMonth.year &&
                transaction.date.month == _selectedMonth.month &&
                transaction.userId == _userId; // Filter by userId
          }).toList();

      _processTransactionsByCategory(filteredTransactions);

      setState(() {
        _monthTransactions = filteredTransactions;
      });
    } catch (e) {
      print('Error loading transactions: $e');
    }
  }

  Future<void> _loadTransactions() async {
    try {
      if (_userId == null) return;

      final transactions = await TransactionService.getAllTransactions();

      // Filter transactions by current user ID
      final userTransactions =
          transactions.where((t) => t.userId == _userId).toList();

      setState(() {
        _allTransactions = userTransactions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBudgetData() async {
    try {
      if (_userId == null) return;

      // Get the current month name to match with the budget data format
      final currentMonthName = DateFormat('MMMM').format(_selectedMonth);

      // Check if budget exists for this month
      final hasBudget = await BudgetDatabase.instance.hasBudget(
        currentMonthName,
      );

      if (hasBudget) {
        // Fetch income value
        final income = await BudgetDatabase.instance.getIncome(
          currentMonthName,
        );

        // Fetch paychecks to calculate total
        final paychecks = await BudgetDatabase.instance.getPaychecks(
          currentMonthName,
        );

        // Calculate total of expected paychecks
        final totalPaychecks = paychecks.fold<double>(
          0.0,
          (sum, paycheck) => sum + (paycheck['amount'] as double),
        );

        setState(() {
          _hasBudget = hasBudget;
          _budgetedIncome = income;
          _budgetedPaychecks = totalPaychecks;
        });
      } else {
        setState(() {
          _hasBudget = false;
          _budgetedIncome = 0.0;
          _budgetedPaychecks = 0.0;
        });
      }
    } catch (e) {
      print('Error loading budget data: $e');
    }
  }

  void _processTransactionsByCategory(List<Transaction> transactions) {
    _expensesByCategory.clear();
    _incomeByCategory.clear();
    _totalExpenses = 0;
    _totalIncome = 0;

    for (var transaction in transactions) {
      if (transaction.isExpense) {
        _expensesByCategory[transaction.categoryId] =
            (_expensesByCategory[transaction.categoryId] ?? 0) +
            transaction.amount;
        _totalExpenses += transaction.amount;
      } else {
        _incomeByCategory[transaction.categoryId] =
            (_incomeByCategory[transaction.categoryId] ?? 0) +
            transaction.amount;
        _totalIncome += transaction.amount;
      }
    }
  }

  void _changeMonth(int monthOffset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + monthOffset,
      );
    });
    _loadData(); // Load both transactions and budget data
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () => _changeMonth(-1),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        'Income',
                        _hasBudget ? _budgetedPaychecks : _totalIncome,
                        Colors.green,
                        Icons.arrow_upward,
                        _hasBudget ? 'Budgeted' : 'Actual',
                      ),
                      _buildSummaryItem(
                        'Expenses',
                        _totalExpenses,
                        Colors.red,
                        Icons.arrow_downward,
                        'Actual',
                      ),
                      _buildSummaryItem(
                        'Balance',
                        (_hasBudget ? _budgetedPaychecks : _totalIncome) -
                            _totalExpenses,
                        ((_hasBudget ? _budgetedPaychecks : _totalIncome) -
                                    _totalExpenses) >=
                                0
                            ? Colors.blue
                            : Colors.redAccent,
                        ((_hasBudget ? _budgetedPaychecks : _totalIncome) -
                                    _totalExpenses) >=
                                0
                            ? Icons.check_circle
                            : Icons.warning,
                        '',
                      ),
                    ],
                  ),
                  if (_hasBudget)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Income is based on your budgeted paychecks',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_totalExpenses == 0)
            _buildEmptyStateCard(
              'No expense data available for this month.',
              Colors.amber,
            )
          else
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expenses by Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180, // Reduced from 200
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(
                            maxWidth: 200,
                          ), // Reduced from 280
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 35, // Reduced from 40
                              sections: _buildPieChartSections(
                                _expensesByCategory,
                              ),
                              pieTouchData: PieTouchData(
                                touchCallback: (
                                  FlTouchEvent event,
                                  pieTouchResponse,
                                ) {
                                  // Optional: Handle touch interactions
                                },
                              ),
                            ),
                            swapAnimationDuration: const Duration(
                              milliseconds: 150,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Category Details',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _buildLegend(_expensesByCategory),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          if (!_isLoading && _totalIncome > 0)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Income by Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180, // Reduced from 200
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(
                            maxWidth: 200,
                          ), // Reduced from 280
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 35, // Reduced from 40
                              sections: _buildPieChartSections(
                                _incomeByCategory,
                              ),
                              pieTouchData: PieTouchData(
                                touchCallback: (
                                  FlTouchEvent event,
                                  pieTouchResponse,
                                ) {
                                  // Optional: Handle touch interactions
                                },
                              ),
                            ),
                            swapAnimationDuration: const Duration(
                              milliseconds: 150,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Category Details',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _buildLegend(_incomeByCategory),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          if (!_isLoading && _expensesByCategory.isNotEmpty)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Strategies to Reduce Spending',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSpendingStrategies(),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    double amount,
    Color color,
    IconData icon,
    String label,
  ) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          radius: 24,
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 14)),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (label.isNotEmpty)
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    Map<String, double> categoryData,
  ) {
    if (categoryData.isEmpty) return [];

    List<MapEntry<String, double>> sortedEntries =
        categoryData.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    double total = categoryData.values.fold(0, (sum, value) => sum + value);

    return sortedEntries.map((entry) {
      final category = Categories.findCategoryById(entry.key);
      final percentValue = (entry.value / total) * 100;
      final displayTitle =
          percentValue >= 12
              ? '${percentValue.toStringAsFixed(0)}%'
              : ''; // Increased threshold from 10 to 12

      return PieChartSectionData(
        color: _categoryColors[entry.key] ?? Colors.grey,
        value: entry.value,
        title: displayTitle,
        radius: 60, // Reduced from 90
        titleStyle: const TextStyle(
          fontSize: 10, // Reduced from 12
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        ),
        titlePositionPercentageOffset: 0.5, // Reduced from 0.55
        badgeWidget:
            percentValue < 12 &&
                    percentValue >=
                        6 // Adjusted thresholds from 10/5 to 12/6
                ? _buildSmallBadge(_categoryColors[entry.key] ?? Colors.grey)
                : null,
        badgePositionPercentageOffset: 0.7, // Reduced from 0.8
      );
    }).toList();
  }

  Widget? _buildSmallBadge(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
    );
  }

  Widget _buildLegend(Map<String, double> categoryData) {
    if (categoryData.isEmpty) return Container();

    List<MapEntry<String, double>> sortedEntries =
        categoryData.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 16.0,
      runSpacing: 12.0,
      children:
          sortedEntries.map((entry) {
            final category = Categories.findCategoryById(entry.key);
            final categoryName = category?.name ?? 'Unknown';
            final percentValue =
                (entry.value /
                    categoryData.values.fold(0, (sum, value) => sum + value)) *
                100;

            return SizedBox(
              width: MediaQuery.of(context).size.width * 0.4,
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _categoryColors[entry.key] ?? Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Row(
                          children: [
                            Text(
                              '\$${entry.value.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${percentValue.toStringAsFixed(1)}%)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildSpendingStrategies() {
    List<MapEntry<String, double>> sortedEntries =
        _expensesByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final topCategories = sortedEntries.take(3).toList();

    if (topCategories.isEmpty) {
      return const Text(
        'Add more transactions to get personalized strategies.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...topCategories.map((entry) {
          final category = Categories.findCategoryById(entry.key);
          final categoryName = category?.name ?? 'Unknown';

          if (entry.key == 'dining_out') {
            return _buildStrategyTile(
              'Reduce Dining Out Expenses',
              'Try meal prepping on weekends and limit restaurant visits to special occasions.',
              Icons.restaurant,
            );
          } else if (entry.key == 'groceries') {
            return _buildStrategyTile(
              'Save on Grocery Shopping',
              'Make a shopping list, use coupons, and buy seasonal produce.',
              Icons.shopping_basket,
            );
          } else if (entry.key == 'entertainment') {
            return _buildStrategyTile(
              'Lower Entertainment Costs',
              'Look for free local events and take advantage of streaming service trials.',
              Icons.movie,
            );
          } else if (entry.key == 'shopping') {
            return _buildStrategyTile(
              'Smart Shopping Habits',
              'Wait 24 hours before making non-essential purchases and compare prices online.',
              Icons.shopping_bag,
            );
          } else if (entry.key == 'utilities') {
            return _buildStrategyTile(
              'Reduce Utility Bills',
              'Adjust your thermostat, use energy-efficient appliances, and fix leaky faucets.',
              Icons.power,
            );
          } else if (entry.key == 'transportation') {
            return _buildStrategyTile(
              'Optimize Transportation Costs',
              'Consider carpooling, public transit, or biking for shorter commutes.',
              Icons.directions_car,
            );
          } else {
            return _buildStrategyTile(
              'Review Your $categoryName Expenses',
              'Track your spending in this category and look for patterns you can optimize.',
              category?.icon ?? Icons.attach_money,
            );
          }
        }),
        _buildStrategyTile(
          'Set Up Automatic Savings',
          'Transfer a small amount to savings each payday before you can spend it.',
          Icons.savings,
        ),
      ],
    );
  }

  Widget _buildStrategyTile(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.1),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard(String message, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 60, color: color.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Navigate to home and then switch to transactions tab
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  );
                  // Set a small delay to ensure the home screen is loaded first
                  Future.delayed(const Duration(milliseconds: 100), () {
                    // Access the tab controller from the parent widget
                    final tabController = DefaultTabController.of(context);
                    // Index 2 is typically the transactions tab in most finance apps
                    tabController.animateTo(2);
                  });
                },
                child: const Text('Add Transactions'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
