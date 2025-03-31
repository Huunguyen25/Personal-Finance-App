import 'package:flutter/material.dart';

class BankingInstitution {
  final String id;
  final String name;
  final IconData icon;

  const BankingInstitution({
    required this.id,
    required this.name,
    required this.icon,
  });
}

// List of common banking institutions
class BankingInstitutions {
  static const chase = BankingInstitution(
    id: 'chase',
    name: 'Chase',
    icon: Icons.account_balance,
  );

  static const bankOfAmerica = BankingInstitution(
    id: 'bank_of_america',
    name: 'Bank of America',
    icon: Icons.account_balance,
  );

  static const wellsFargo = BankingInstitution(
    id: 'wells_fargo',
    name: 'Wells Fargo',
    icon: Icons.account_balance,
  );

  static const citibank = BankingInstitution(
    id: 'citibank',
    name: 'Citibank',
    icon: Icons.account_balance,
  );

  static const capitalOne = BankingInstitution(
    id: 'capital_one',
    name: 'Capital One',
    icon: Icons.credit_card,
  );

  static const discover = BankingInstitution(
    id: 'discover',
    name: 'Discover',
    icon: Icons.credit_card,
  );

  static const other = BankingInstitution(
    id: 'other',
    name: 'Other Institution',
    icon: Icons.account_balance_wallet,
  );

  static final List<BankingInstitution> institutions = [
    chase,
    bankOfAmerica,
    wellsFargo,
    citibank,
    capitalOne,
    discover,
    other,
  ];
}
