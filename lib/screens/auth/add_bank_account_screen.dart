import 'dart:math';

import 'package:flutter/material.dart';
import '../../models/banking_institution.dart';
import '../../services/auth_service.dart';
import '../../models/account.dart';

class AddBankAccountScreen extends StatefulWidget {
  const AddBankAccountScreen({super.key});

  @override
  State<AddBankAccountScreen> createState() => _AddBankAccountScreenState();
}

class _AddBankAccountScreenState extends State<AddBankAccountScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  BankingInstitution? _selectedInstitution;
  List<Account> _addedAccounts = [];
  int? _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the userId from arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('userId')) {
      _userId = args['userId'];
    }
  }

  void _showBankSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Your Bank',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 400,
                child: ListView.builder(
                  itemCount: BankingInstitutions.institutions.length,
                  itemBuilder: (context, index) {
                    final institution = BankingInstitutions.institutions[index];
                    return ListTile(
                      leading: Icon(institution.icon),
                      title: Text(institution.name),
                      onTap: () {
                        Navigator.pop(context);
                        _selectedInstitution = institution;
                        _showBankLoginSheet(institution);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBankLoginSheet(BankingInstitution institution) {
    String username = '';
    String password = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Login to ${institution.name}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Secure login disclaimer
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.security, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'This is a demo. In a real app, we would use a secure service like Plaid.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => username = value,
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      onChanged: (value) => password = value,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          if (username.isNotEmpty && password.isNotEmpty) {
                            Navigator.pop(context);

                            // For demo purposes, show a loading indicator briefly
                            // to simulate bank connection
                            setStateSheet(() => _isLoading = true);

                            Future.delayed(const Duration(seconds: 2), () {
                              // Show account selection screen
                              _showAccountSelectionSheet(institution);
                            });
                          }
                        },
                        child: const Text('Connect to Bank'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAccountSelectionSheet(BankingInstitution institution) {
    // Generate demo accounts for this institution
    List<Map<String, dynamic>> demoAccounts = [
      {
        'name': 'Checking Account',
        'number': '****${Random().nextInt(9999)}',
        'type': 'checking',
      },
      {
        'name': 'Savings Account',
        'number': '****${Random().nextInt(9999)}',
        'type': 'savings',
      },
      {
        'name': 'Credit Card',
        'number': '****${Random().nextInt(9999)}',
        'type': 'credit',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Accounts to Add',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: demoAccounts.length,
                  itemBuilder: (context, index) {
                    final account = demoAccounts[index];
                    return ListTile(
                      title: Text(account['name']),
                      subtitle: Text('Account ${account['number']}'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.pop(context);
                        _showAccountDetailsSheet(
                          institution,
                          account['name'],
                          account['number'],
                          account['type'],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAccountDetailsSheet(
    BankingInstitution institution,
    String accountName,
    String accountNumber,
    String accountType,
  ) {
    double balance = 0.0;
    String fullAccountNumber = accountNumber.replaceFirst(
      '****',
      '${Random().nextInt(9000) + 1000}',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Account Details',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Text('Institution: ${institution.name}'),
                    const SizedBox(height: 8),

                    Text('Account: $accountName'),
                    const SizedBox(height: 8),

                    Text('Account Number: $accountNumber'),
                    const SizedBox(height: 16),

                    const Text('Current Balance'),
                    const SizedBox(height: 8),

                    TextField(
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged:
                          (value) => balance = double.tryParse(value) ?? 0.0,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (_userId != null) {
                            setState(() => _isLoading = true);

                            try {
                              // Create account with the provided details
                              Account account = Account(
                                userId: _userId!,
                                accountName: accountName,
                                accountNumber: fullAccountNumber,
                                balance: balance,
                                isDemo: false,
                              );

                              // Save account to database
                              final savedAccount = await _authService
                                  .createManualAccount(
                                    _userId!,
                                    accountName,
                                    fullAccountNumber,
                                    balance,
                                  );

                              if (savedAccount != null) {
                                setState(() {
                                  _addedAccounts.add(savedAccount);
                                  _isLoading = false;
                                });

                                // Close the bottom sheet
                                Navigator.pop(context);

                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '$accountName added successfully',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              setState(() => _isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error adding account: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Add Account'),
                      ),
                    ),
                    const SizedBox(height: 20),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Your Bank Accounts'),
        automaticallyImplyLeading: false,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Let\'s connect your bank accounts to get started',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 30),

                    // Add Bank Account Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Bank Account'),
                        onPressed: _showBankSelectionSheet,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Added accounts list
                    if (_addedAccounts.isNotEmpty) ...[
                      const Text(
                        'Added Accounts:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Expanded(
                        child: ListView.builder(
                          itemCount: _addedAccounts.length,
                          itemBuilder: (context, index) {
                            final account = _addedAccounts[index];
                            return ListTile(
                              leading: Icon(
                                _getIconForAccountType(account.accountName),
                                color: Colors.blue,
                              ),
                              title: Text(account.accountName),
                              subtitle: Text(
                                'Account ${account.accountNumber}',
                              ),
                              trailing: Text(
                                '\$${account.balance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      account.balance >= 0
                                          ? Colors.green
                                          : Colors.red,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            // Navigate to home screen
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          },
          child: Text(
            _addedAccounts.isEmpty ? 'Skip for Now' : 'Continue to Dashboard',
          ),
        ),
      ),
    );
  }

  IconData _getIconForAccountType(String accountType) {
    switch (accountType.toLowerCase()) {
      case 'checking account':
        return Icons.account_balance;
      case 'savings account':
        return Icons.savings;
      case 'credit card':
        return Icons.credit_card;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
