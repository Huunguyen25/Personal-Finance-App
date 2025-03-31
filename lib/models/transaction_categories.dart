import 'package:flutter/material.dart';

class CategoryGroup {
  final String name;
  final IconData icon;
  final List<TransactionCategory> categories;

  const CategoryGroup({
    required this.name,
    required this.icon,
    required this.categories,
  });
}

class TransactionCategory {
  final String id;
  final String name;
  final IconData icon;

  const TransactionCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

// Define all category groups with their categories
class Categories {
  // Essentials
  static final essentials = CategoryGroup(
    name: '🏠 Essentials',
    icon: Icons.home,
    categories: [
      TransactionCategory(
        id: 'rent_mortgage',
        name: 'Rent/Mortgage',
        icon: Icons.apartment,
      ),
      TransactionCategory(
        id: 'utilities',
        name: 'Utilities',
        icon: Icons.power,
      ),
      TransactionCategory(
        id: 'groceries',
        name: 'Groceries',
        icon: Icons.shopping_basket,
      ),
      TransactionCategory(
        id: 'transportation',
        name: 'Transportation',
        icon: Icons.directions_car,
      ),
    ],
  );

  // Lifestyle & Leisure
  static final lifestyle = CategoryGroup(
    name: '🍔 Lifestyle & Leisure',
    icon: Icons.restaurant,
    categories: [
      TransactionCategory(
        id: 'dining_out',
        name: 'Dining Out',
        icon: Icons.restaurant_menu,
      ),
      TransactionCategory(
        id: 'entertainment',
        name: 'Entertainment',
        icon: Icons.movie,
      ),
      TransactionCategory(
        id: 'shopping',
        name: 'Shopping',
        icon: Icons.shopping_bag,
      ),
    ],
  );

  // Financial
  static final financial = CategoryGroup(
    name: '💳 Financial',
    icon: Icons.account_balance,
    categories: [
      TransactionCategory(id: 'savings', name: 'Savings', icon: Icons.savings),
      TransactionCategory(
        id: 'debt_payments',
        name: 'Debt Payments',
        icon: Icons.credit_card,
      ),
      TransactionCategory(
        id: 'investments',
        name: 'Investments',
        icon: Icons.trending_up,
      ),
    ],
  );

  // Health & Wellness
  static final health = CategoryGroup(
    name: '❤️ Health & Wellness',
    icon: Icons.favorite,
    categories: [
      TransactionCategory(
        id: 'insurance',
        name: 'Insurance',
        icon: Icons.health_and_safety,
      ),
      TransactionCategory(
        id: 'medical',
        name: 'Medical',
        icon: Icons.medical_services,
      ),
    ],
  );

  // Personal Growth
  static final personalGrowth = CategoryGroup(
    name: '🎓 Personal Growth',
    icon: Icons.school,
    categories: [
      TransactionCategory(
        id: 'education',
        name: 'Education',
        icon: Icons.menu_book,
      ),
    ],
  );

  // Other Expenses
  static final other = CategoryGroup(
    name: '🎁 Other Expenses',
    icon: Icons.more_horiz,
    categories: [
      TransactionCategory(
        id: 'gifts_donations',
        name: 'Gifts & Donations',
        icon: Icons.card_giftcard,
      ),
      TransactionCategory(id: 'travel', name: 'Travel', icon: Icons.flight),
      TransactionCategory(
        id: 'subscriptions',
        name: 'Subscriptions',
        icon: Icons.subscriptions,
      ),
      TransactionCategory(
        id: 'business',
        name: 'Business Expenses',
        icon: Icons.business_center,
      ),
      TransactionCategory(id: 'self_care', name: 'Self-Care', icon: Icons.spa),
      TransactionCategory(
        id: 'miscellaneous',
        name: 'Miscellaneous',
        icon: Icons.category,
      ),
    ],
  );

  // Income categories
  static final income = CategoryGroup(
    name: '💰 Income',
    icon: Icons.account_balance_wallet,
    categories: [
      TransactionCategory(id: 'salary', name: 'Salary', icon: Icons.work),
      TransactionCategory(
        id: 'freelance',
        name: 'Freelance',
        icon: Icons.computer,
      ),
      TransactionCategory(
        id: 'investments',
        name: 'Investments',
        icon: Icons.attach_money,
      ),
      TransactionCategory(
        id: 'gifts',
        name: 'Gifts Received',
        icon: Icons.redeem,
      ),
      TransactionCategory(
        id: 'other_income',
        name: 'Other Income',
        icon: Icons.payments,
      ),
    ],
  );

  // All category groups
  static final List<CategoryGroup> expenseGroups = [
    essentials,
    lifestyle,
    financial,
    health,
    personalGrowth,
    other,
  ];

  // Income group
  static final List<CategoryGroup> incomeGroups = [income];

  // Get all categories (flattened)
  static List<TransactionCategory> getAllCategories() {
    List<TransactionCategory> result = [];
    for (var group in [...expenseGroups, ...incomeGroups]) {
      result.addAll(group.categories);
    }
    return result;
  }

  // Find category by ID
  static TransactionCategory? findCategoryById(String id) {
    final allCategories = getAllCategories();
    try {
      return allCategories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }
}
