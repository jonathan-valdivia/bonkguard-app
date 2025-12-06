// lib/models/fuel_item.dart

enum FuelItemType { drinkMix, gel, solid, other }

class FuelItem {
  final String id; // e.g. 'maurten_320'
  final String name; // e.g. 'Maurten 320'
  final FuelItemType type;

  /// Carbs per serving in grams
  final int carbsPerServing;

  /// Calories per serving (optional but useful)
  final int? caloriesPerServing;

  /// Optional: extra info like "500ml bottle" or "one bar"
  final String? description;

  const FuelItem({
    required this.id,
    required this.name,
    required this.type,
    required this.carbsPerServing,
    this.caloriesPerServing,
    this.description,
  });

  /// For saving later to Firestore if we want
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'carbsPerServing': carbsPerServing,
      'caloriesPerServing': caloriesPerServing,
      'description': description,
    };
  }

  factory FuelItem.fromMap(Map<String, dynamic> map) {
    return FuelItem(
      id: map['id'] as String,
      name: map['name'] as String,
      type: FuelItemType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => FuelItemType.other,
      ),
      carbsPerServing: map['carbsPerServing'] as int,
      caloriesPerServing: map['caloriesPerServing'] as int?,
      description: map['description'] as String?,
    );
  }
}
