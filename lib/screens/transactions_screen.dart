import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/transaction.dart';
import '../models/transaction_categories.dart';
import '../services/transaction_service.dart';
import '../services/auth_service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  final AuthService _authService = AuthService();

  // Use the list of transactions from shared service
  List<Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  // Load saved transactions
  Future<void> _loadTransactions() async {
    try {
      final transactions = await TransactionService.getAllTransactions();
      setState(() {
        _transactions = transactions;
      });
    } catch (e) {
      // Handle error - could show a snackbar here
      print('Error loading transactions: $e');
    }
  }

  // Filtered transactions based on selected date
  List<Transaction> get _filteredTransactions {
    return _transactions.where((transaction) {
      return transaction.date.year == _selectedDay.year &&
          transaction.date.month == _selectedDay.month &&
          transaction.date.day == _selectedDay.day;
    }).toList();
  }

  // Get event markers for calendar
  Map<DateTime, List<Transaction>> get _transactionsByDay {
    final Map<DateTime, List<Transaction>> result = {};

    for (final transaction in _transactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );

      if (result[date] == null) {
        result[date] = [];
      }

      result[date]!.add(transaction);
    }

    return result;
  }

  // Get list of events for a day
  List<Transaction> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _transactionsByDay[normalizedDay] ?? [];
  }

  // Add functionality to create a new transaction
  Future<void> _addTransaction(
    String title,
    String categoryId,
    double amount,
    bool isExpense,
  ) async {
    try {
      // Get the current user ID
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User is not logged in')));
        return;
      }

      final newTransaction = Transaction(
        userId: userId,
        title: title,
        categoryId: categoryId,
        amount: amount,
        isExpense: isExpense,
        date: _selectedDay,
      );

      // Save the transaction to the database
      final success = await TransactionService.saveTransaction(newTransaction);

      if (success) {
        // Add to local state for immediate UI update
        setState(() {
          _transactions.add(newTransaction);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save transaction')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Replace dialog with bottom sheet
  void _showAddTransactionBottomSheet(BuildContext context) {
    bool isExpense = true;
    String title = '';
    String categoryId = isExpense ? 'miscellaneous' : 'other_income';
    String amount = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            // Get appropriate category groups based on transaction type
            final categoryGroups =
                isExpense ? Categories.expenseGroups : Categories.incomeGroups;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Transaction',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Transaction type toggle
                    const Text('Transaction Type'),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text('Expense'),
                          icon: Icon(Icons.arrow_downward),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text('Income'),
                          icon: Icon(Icons.arrow_upward),
                        ),
                      ],
                      selected: {isExpense},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setStateSheet(() {
                          isExpense = newSelection.first;
                          // Reset category when switching between expense/income
                          categoryId =
                              isExpense ? 'miscellaneous' : 'other_income';
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Title field
                    const Text('Title'),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'e.g., Grocery Shopping',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        title = value;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category selection
                    const Text('Category'),
                    const SizedBox(height: 8),

                    // Category group expansion panels
                    for (var group in categoryGroups)
                      ExpansionTile(
                        leading: Icon(group.icon),
                        title: Text(group.name),
                        children:
                            group.categories.map((category) {
                              return RadioListTile<String>(
                                title: Row(
                                  children: [
                                    Icon(category.icon, size: 20),
                                    const SizedBox(width: 8),
                                    Text(category.name),
                                  ],
                                ),
                                value: category.id,
                                groupValue: categoryId,
                                onChanged: (value) {
                                  setStateSheet(() {
                                    categoryId = value!;
                                  });
                                },
                              );
                            }).toList(),
                      ),

                    const SizedBox(height: 16),

                    // Amount field
                    const Text('Amount'),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (value) {
                        amount = value;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Add Transaction Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (title.isNotEmpty && amount.isNotEmpty) {
                            _addTransaction(
                              title,
                              categoryId,
                              double.parse(amount),
                              isExpense,
                            );
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Add Transaction'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
              eventLoader: _getEventsForDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.redAccent,
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

        // Date display and add transaction button
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transactions for ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle),
                color: Theme.of(context).colorScheme.primary,
                onPressed: () {
                  // Show bottom sheet to add a new transaction
                  _showAddTransactionBottomSheet(context);
                },
              ),
            ],
          ),
        ),

        // Transactions list
        Expanded(
          child:
              _filteredTransactions.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No transactions for this day.'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            _showAddTransactionBottomSheet(context);
                          },
                          child: const Text('Add Transaction'),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _filteredTransactions[index];
                      // Find the category from our predefined list
                      final category = Categories.findCategoryById(
                        transaction.categoryId,
                      );

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 8.0,
                        ),
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
                          subtitle: Text(category?.name ?? 'Miscellaneous'),
                          trailing: Text(
                            '\$${transaction.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  transaction.isExpense
                                      ? Colors.red
                                      : Colors.green,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
