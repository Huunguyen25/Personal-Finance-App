import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/auth_service.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';
import '../models/transaction_categories.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/transaction_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  final AuthService _authService = AuthService();
  List<Account> _accounts = [];
  bool _isLoading = true;

  // Use transactions from the shared service
  List<Transaction> _transactions = [];

  // Maximum transactions to display on home screen
  final int _maxTransactionsToDisplay = 4;

  // Set of account IDs selected for display
  Set<int?> _selectedAccountIds = {};

  @override
  void initState() {
    super.initState();
    _loadUserAccounts();
    _loadDayTransactions(_selectedDay);
    _loadSelectedAccountIds();
  }

  // Load selected account IDs from shared preferences
  Future<void> _loadSelectedAccountIds() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? idsString = prefs.getStringList('selected_account_ids');

    if (idsString != null) {
      setState(() {
        _selectedAccountIds =
            idsString
                .map((id) => int.tryParse(id))
                .where((id) => id != null)
                .toSet();
      });
    }
  }

  // Save selected account IDs to shared preferences
  Future<void> _saveSelectedAccountIds() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> idsString =
        _selectedAccountIds
            .where((id) => id != null)
            .map((id) => id.toString())
            .toList();

    await prefs.setStringList('selected_account_ids', idsString);
  }

  Future<void> _loadUserAccounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await _authService.getCurrentUserId();
      if (userId != null) {
        final accounts = await _authService.getUserAccounts(userId);
        setState(() {
          _accounts = accounts;
          _isLoading = false;

          // If no accounts are selected yet, select all accounts by default
          if (_selectedAccountIds.isEmpty && accounts.isNotEmpty) {
            _selectedAccountIds = accounts.map((acc) => acc.id).toSet();
            _saveSelectedAccountIds();
          }
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading accounts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load transactions for the selected day
  Future<void> _loadDayTransactions(DateTime day) async {
    try {
      final transactions = await TransactionService.getTransactionsForDate(day);
      setState(() {
        _transactions = transactions;
      });
    } catch (e) {
      print('Error loading transactions: $e');
    }
  }

  // Check if selected day is today
  bool get _isSelectedDayToday {
    final now = DateTime.now();
    return _selectedDay.year == now.year &&
        _selectedDay.month == now.month &&
        _selectedDay.day == now.day;
  }

  // Format date for display (Today, Yesterday, or date format)
  String _getFormattedDayText() {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (_isSelectedDayToday) {
      return "Today's Transactions";
    } else if (_selectedDay.year == yesterday.year &&
        _selectedDay.month == yesterday.month &&
        _selectedDay.day == yesterday.day) {
      return "Yesterday's Transactions";
    } else {
      return "${DateFormat('MMM d, yyyy').format(_selectedDay)} Transactions";
    }
  }

  // Calculate total balance only from selected accounts
  double get _totalBalance {
    if (_selectedAccountIds.isEmpty) {
      return _accounts.fold(0, (sum, account) => sum + account.balance);
    } else {
      return _accounts
          .where((account) => _selectedAccountIds.contains(account.id))
          .fold(0, (sum, account) => sum + account.balance);
    }
  }

  // Get selected accounts
  List<Account> get _selectedAccounts {
    return _accounts
        .where((account) => _selectedAccountIds.contains(account.id))
        .toList();
  }

  IconData _getIconForAccountType(String accountType) {
    switch (accountType.toLowerCase()) {
      case 'checking account':
        return Icons.account_balance;
      case 'savings account':
        return Icons.savings;
      case 'investment account':
        return Icons.trending_up;
      case 'credit card':
        return Icons.credit_card;
      default:
        return Icons.account_balance_wallet;
    }
  }

  void _showAccountDetailsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Accounts'),
              content: SizedBox(
                width: double.maxFinite,
                child:
                    _accounts.isEmpty
                        ? const Center(child: Text('No accounts found'))
                        : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                'Select accounts to display on home screen',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const Divider(),
                            Expanded(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _accounts.length,
                                itemBuilder: (context, index) {
                                  final account = _accounts[index];
                                  final isSelected = _selectedAccountIds
                                      .contains(account.id);

                                  return CheckboxListTile(
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      setStateDialog(() {
                                        if (value == true) {
                                          _selectedAccountIds.add(account.id);
                                        } else {
                                          _selectedAccountIds.remove(
                                            account.id,
                                          );
                                        }
                                      });
                                    },
                                    title: Text(account.accountName),
                                    subtitle: Text(
                                      'Account ****${account.accountNumber.substring(account.accountNumber.length - 4)}',
                                    ),
                                    secondary: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.grey.shade100,
                                          child: Icon(
                                            _getIconForAccountType(
                                              account.accountName,
                                            ),
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '\$${account.balance.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                account.balance >= 0
                                                    ? Colors.green
                                                    : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Save selected accounts and update UI
                    _saveSelectedAccountIds();
                    setState(() {});
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh accounts when screen gets focus
    _loadUserAccounts();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the entire content in SingleChildScrollView to fix the layout issue
    return SingleChildScrollView(
      child: Column(
        children: [
          // Account balance section with improved UI
          Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedAccountIds.isEmpty ||
                              _selectedAccountIds.length == _accounts.length
                          ? 'Total Balance'
                          : 'Selected Balance',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_selectedAccounts.length} ${_selectedAccounts.length == 1 ? 'Account' : 'Accounts'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                    : Text(
                      '\$${_totalBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                const SizedBox(height: 20),

                // Account breakdown - show a small preview of selected accounts
                if (_selectedAccounts.isNotEmpty && !_isLoading)
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          _selectedAccounts.length > 3
                              ? 3
                              : _selectedAccounts.length,
                      itemBuilder: (context, index) {
                        final account = _selectedAccounts[index];
                        return Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                account.accountName.length > 10
                                    ? '${account.accountName.substring(0, 10)}...'
                                    : account.accountName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${account.balance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),

                // View details button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showAccountDetailsDialog,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedAccountIds.isEmpty ||
                                  _selectedAccountIds.length == _accounts.length
                              ? 'View All Accounts'
                              : 'Select Accounts',
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Calendar section
          Card(
            margin: const EdgeInsets.all(8.0),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _loadDayTransactions(selectedDay);
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
              ),
            ),
          ),

          // Date display
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transactions for ${DateFormat('MMM d, yyyy').format(_selectedDay)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('${_transactions.length} transactions'),
              ],
            ),
          ),

          // Transactions section with limited display
          Container(
            height: 350, // Increased height for better visibility
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getFormattedDayText(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        // Refresh button
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => _loadDayTransactions(_selectedDay),
                          tooltip: 'Refresh transactions',
                        ),
                        // Go to transactions screen button
                        if (_transactions.length > _maxTransactionsToDisplay)
                          TextButton(
                            onPressed: () {
                              // Navigate to transactions tab
                              DefaultTabController.of(context).animateTo(1);
                            },
                            child: const Text('View All'),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child:
                      _transactions.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No transactions for ${_isSelectedDayToday ? "today" : DateFormat('MMM d, yyyy').format(_selectedDay)}',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Limited transactions list
                              Expanded(
                                child: ListView.builder(
                                  itemCount:
                                      _transactions.length >
                                              _maxTransactionsToDisplay
                                          ? _maxTransactionsToDisplay
                                          : _transactions.length,
                                  itemBuilder: (context, index) {
                                    final transaction = _transactions[index];
                                    // Find the category from our predefined list
                                    final category =
                                        Categories.findCategoryById(
                                          transaction.categoryId,
                                        );

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              transaction.isExpense
                                                  ? Colors.red.shade100
                                                  : Colors.green.shade100,
                                          child: Icon(
                                            category?.icon ??
                                                (transaction.isExpense
                                                    ? Icons.arrow_downward
                                                    : Icons.arrow_upward),
                                            color:
                                                transaction.isExpense
                                                    ? Colors.red
                                                    : Colors.green,
                                          ),
                                        ),
                                        title: Text(transaction.title),
                                        subtitle: Text(
                                          category?.name ?? 'Miscellaneous',
                                        ),
                                        trailing: Text(
                                          '\$${transaction.amount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color:
                                                transaction.isExpense
                                                    ? Colors.red
                                                    : Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Show "x more transactions" message if needed
                              if (_transactions.length >
                                  _maxTransactionsToDisplay)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Center(
                                    child: Text(
                                      '${_transactions.length - _maxTransactionsToDisplay} more transactions',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                ),
              ],
            ),
          ),

          // Add bottom padding to ensure content isn't cut off
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
