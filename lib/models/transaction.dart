import 'package:uuid/uuid.dart';

class Transaction {
  final String id;
  final int userId;
  final String title;
  final String categoryId;
  final double amount;
  final bool isExpense;
  final DateTime date;
  final String? note;

  Transaction({
    String? id,
    required this.userId,
    required this.title,
    required this.categoryId,
    required this.amount,
    required this.isExpense,
    required this.date,
    this.note,
  }) : id = id ?? const Uuid().v4();

  // Convert transaction to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'categoryId': categoryId,
      'amount': amount,
      'isExpense': isExpense ? 1 : 0,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  // Create transaction from Map from SQLite
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      categoryId: map['categoryId'] ?? map['category'] ?? 'miscellaneous',
      amount:
          map['amount'] is int
              ? (map['amount'] as int).toDouble()
              : map['amount'],
      isExpense: map['isExpense'] == 1,
      date: DateTime.parse(map['date']),
      note: map['note'],
    );
  }
}
