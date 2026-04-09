import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final double amount;
  final String description;
  final DateTime date;
  final String paidBy;
  final List<String> participants;
  final TransactionType type;
  final String category; // 'general', 'khorochi', 'hingane'
  final String? paidByName;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.description,
    required this.date,
    required this.paidBy,
    required this.participants,
    required this.type,
    this.category = 'general',
    this.paidByName,
  });

  factory TransactionModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      amount: (data['amount'] as num).toDouble(),
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      paidBy: data['paidBy'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      type: TransactionType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'expense'),
        orElse: () => TransactionType.expense,
      ),
      category: data['category'] ?? 'general',
      paidByName: data['paidByName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'description': description,
      'date': Timestamp.fromDate(date),
      'paidBy': paidBy,
      'participants': participants,
      'type': type.name,
      'category': category,
      'paidByName': paidByName,
    };
  }
}
