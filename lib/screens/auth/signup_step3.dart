import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import 'dart:math';

class SignupStep3Screen extends StatefulWidget {
  const SignupStep3Screen({super.key});

  @override
  State<SignupStep3Screen> createState() => _SignupStep3ScreenState();
}

class _SignupStep3ScreenState extends State<SignupStep3Screen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _demoAccounts = [];
  int? _selectedAccountIndex;

  @override
  void initState() {
    super.initState();
    _generateDemoAccounts();
  }

  void _generateDemoAccounts() {
    final random = Random();
    _demoAccounts = [
      {
        'name': 'Checking Account',
        'number': '****${random.nextInt(9000) + 1000}',
        'balance': (5000 + random.nextDouble() * 5000).toStringAsFixed(2),
        'icon': Icons.account_balance,
        'fullNumber': _generateFullAccountNumber(),
      },
      {
        'name': 'Savings Account',
        'number': '****${random.nextInt(9000) + 1000}',
        'balance': (5000 + random.nextDouble() * 5000).toStringAsFixed(2),
        'icon': Icons.savings,
        'fullNumber': _generateFullAccountNumber(),
      },
      {
        'name': 'Investment Account',
        'number': '****${random.nextInt(9000) + 1000}',
        'balance': (5000 + random.nextDouble() * 5000).toStringAsFixed(2),
        'icon': Icons.trending_up,
        'fullNumber': _generateFullAccountNumber(),
      },
      {
        'name': 'Credit Card',
        'number': '****${random.nextInt(9000) + 1000}',
        'balance': (5000 + random.nextDouble() * 5000).toStringAsFixed(2),
        'icon': Icons.credit_card,
        'fullNumber': _generateFullAccountNumber(),
      },
    ];
  }

  String _generateFullAccountNumber() {
    Random random = Random();
    String accountNumber = '';
    for (int i = 0; i < 10; i++) {
      accountNumber += random.nextInt(10).toString();
    }
    return accountNumber;
  }

  Future<void> _createAccountWithDemoAccounts() async {
    if (_selectedAccountIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account to continue.')),
      );
      return;
    }

    final userData =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user
      final user = User(
        email: userData['email'],
        phone: userData['phone'],
        firstName: userData['firstName'],
        lastName: userData['lastName'],
        dateOfBirth: userData['dateOfBirth'],
        password: userData['password'],
      );

      final userId = await _authService.registerUser(user);

      if (userId != null) {
        // Save user session to stay logged in
        await _authService.saveUserSession(userId);

        // Create selected demo account
        final selectedAccount = _demoAccounts[_selectedAccountIndex!];
        await _authService.createSelectedDemoAccount(
          userId,
          selectedAccount['name'],
          selectedAccount['fullNumber'],
          double.parse(selectedAccount['balance']),
        );

        if (!mounted) return;

        // Navigate to home screen
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create account. Please try again.'),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createAccountWithoutDemoAccounts() async {
    final userData =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user
      final user = User(
        email: userData['email'],
        phone: userData['phone'],
        firstName: userData['firstName'],
        lastName: userData['lastName'],
        dateOfBirth: userData['dateOfBirth'],
        password: userData['password'],
      );

      final userId = await _authService.registerUser(user);

      if (userId != null) {
        // Save user session to stay logged in
        await _authService.saveUserSession(userId);

        if (!mounted) return;

        // Navigate to add bank accounts
        Navigator.pushReplacementNamed(
          context,
          '/add_bank_account',
          arguments: {'userId': userId},
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create account. Please try again.'),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Step 3 of 3',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select Account Type',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'You can start with demo accounts or create your own account from scratch.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              const Text(
                'Demo Accounts Available:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _demoAccounts.length,
                  itemBuilder: (context, index) {
                    final account = _demoAccounts[index];
                    final bool isSelected = _selectedAccountIndex == index;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected ? Colors.green : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedAccountIndex = index;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  isSelected
                                      ? Colors.green
                                      : Colors.green.shade100,
                              child: Icon(
                                account['icon'] as IconData,
                                color: isSelected ? Colors.white : Colors.green,
                              ),
                            ),
                            title: Text(
                              account['name'],
                              style: TextStyle(
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text('Account ${account['number']}'),
                            trailing: Text(
                              '\$${account['balance']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isSelected ? Colors.green : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createAccountWithDemoAccounts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Use Demo Accounts',
                          style: TextStyle(fontSize: 16),
                        ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed:
                    _isLoading ? null : _createAccountWithoutDemoAccounts,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'No Demo Bank',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _createAccountWithoutDemoAccounts,
                  child: const Text(
                    "I don't see my bank - Add manually",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
