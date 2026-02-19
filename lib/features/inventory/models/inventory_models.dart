import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  final String id;
  final String name;
  final double quantity;
  final String unit; // 'kg', 'ltr', 'pcs'
  final String category;
  final DateTime? lastPurchased;

  InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    this.lastPurchased,
  });

  InventoryItem copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    String? category,
    DateTime? lastPurchased,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      lastPurchased: lastPurchased ?? this.lastPurchased,
    );
  }

  factory InventoryItem.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryItem(
      id: doc.id,
      name: data['name'] ?? '',
      quantity: (data['quantity'] as num).toDouble(),
      unit: data['unit'] ?? 'pcs',
      category: data['category'] ?? 'General',
      lastPurchased: data['lastPurchased'] != null
          ? (data['lastPurchased'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'lastPurchased': lastPurchased != null
          ? Timestamp.fromDate(lastPurchased!)
          : null,
    };
  }
}

class ShoppingListItem {
  String name;
  bool isBought;
  double quantity;
  String unit;

  ShoppingListItem({
    required this.name,
    this.isBought = false,
    this.quantity = 1,
    this.unit = 'pcs',
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'isBought': isBought,
    'quantity': quantity,
    'unit': unit,
  };

  factory ShoppingListItem.fromMap(Map<String, dynamic> map) =>
      ShoppingListItem(
        name: map['name'] ?? '',
        isBought: map['isBought'] ?? false,
        quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
        unit: map['unit'] ?? 'pcs',
      );
}
