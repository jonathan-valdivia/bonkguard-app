import 'package:cloud_firestore/cloud_firestore.dart';

class FuelItem {
  final String id;
  final String? userId; // null for default fuels
  final String name;
  final String brand;
  final int carbsPerServing;     // grams
  final int caloriesPerServing;  // kcal
  final int sodiumMg;            // mg
  final String? notes;
  final bool isDefault;

  FuelItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.brand,
    required this.carbsPerServing,
    required this.caloriesPerServing,
    required this.sodiumMg,
    this.notes,
    required this.isDefault,
  });

  /// Generic JSON for app/tests (not Firestore-specific)
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'brand': brand,
      'carbsPerServing': carbsPerServing,
      'caloriesPerServing': caloriesPerServing,
      'sodiumMg': sodiumMg,
      'notes': notes,
      'isDefault': isDefault,
    };
  }

  factory FuelItem.fromJson(String id, Map<String, dynamic> json) {
    return FuelItem(
      id: id,
      userId: json['userId'] as String?,
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      carbsPerServing: (json['carbsPerServing'] ?? 0) as int,
      caloriesPerServing: (json['caloriesPerServing'] ?? 0) as int,
      sodiumMg: (json['sodiumMg'] ?? 0) as int,
      notes: json['notes'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  /// Firestore → FuelItem
  factory FuelItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return FuelItem(
      id: doc.id,
      userId: data['userId'] as String?,
      name: data['name'] as String? ?? '',
      brand: data['brand'] as String? ?? '',
      carbsPerServing: (data['carbsPerServing'] ?? 0) as int,
      caloriesPerServing: (data['caloriesPerServing'] ?? 0) as int,
      sodiumMg: (data['sodiumMg'] ?? 0) as int,
      notes: data['notes'] as String?,
      isDefault: data['isDefault'] as bool? ?? false,
    );
  }
}
