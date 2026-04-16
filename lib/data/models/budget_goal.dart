class BudgetGoal {
  final int? id;
  final String category;
  final String month; // e.g. '2025-04'
  final double limitAmount;

  BudgetGoal({
    this.id,
    required this.category,
    required this.month,
    required this.limitAmount,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'category': category,
        'month': month,
        'limitAmount': limitAmount,
      };

  factory BudgetGoal.fromMap(Map<String, dynamic> map) => BudgetGoal(
        id: map['id'],
        category: map['category'],
        month: map['month'],
        limitAmount: map['limitAmount'],
      );
}