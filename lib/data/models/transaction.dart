class Transaction {
  final int? id;
  final String description;
  final double amount;
  final String currency;
  final double convertedAmount;
  final String category;
  final String type; // 'income' or 'expense'
  final int date; // epoch ms
  final String note;

  Transaction({
    this.id,
    required this.description,
    required this.amount,
    required this.currency,
    required this.convertedAmount,
    required this.category,
    required this.type,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'description': description,
        'amount': amount,
        'currency': currency,
        'convertedAmount': convertedAmount,
        'category': category,
        'type': type,
        'date': date,
        'note': note,
      };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['id'],
        description: map['description'],
        amount: map['amount'],
        currency: map['currency'],
        convertedAmount: map['convertedAmount'],
        category: map['category'],
        type: map['type'],
        date: map['date'],
        note: map['note'] ?? '',
      );
}