class Account {
  final int? id;
  final int userId;
  final String accountName;
  final String accountNumber;
  final double balance;
  final bool isDemo;

  Account({
    this.id,
    required this.userId,
    required this.accountName,
    required this.accountNumber,
    required this.balance,
    required this.isDemo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'accountName': accountName,
      'accountNumber': accountNumber,
      'balance': balance,
      'isDemo': isDemo ? 1 : 0,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      userId: map['userId'],
      accountName: map['accountName'],
      accountNumber: map['accountNumber'],
      balance: map['balance'],
      isDemo: map['isDemo'] == 1,
    );
  }
}
