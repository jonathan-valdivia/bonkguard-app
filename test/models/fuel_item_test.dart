// test/models/fuel_item_test.dart
import 'package:bonkguard_app/models/fuel_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FuelItem model', () {
    test('toJson and fromJson round-trip correctly', () {
      final original = FuelItem(
        id: 'fuel123',
        userId: 'user1',
        name: 'Citrus Gel 30g',
        brand: 'TestBrand',
        carbsPerServing: 30,
        caloriesPerServing: 120,
        sodiumMg: 150,
        notes: 'Caffeinated',
        isDefault: false,
      );

      final json = original.toJson();
      final copy = FuelItem.fromJson(original.id, json);

      expect(copy.id, original.id);
      expect(copy.userId, original.userId);
      expect(copy.name, original.name);
      expect(copy.brand, original.brand);
      expect(copy.carbsPerServing, original.carbsPerServing);
      expect(copy.caloriesPerServing, original.caloriesPerServing);
      expect(copy.sodiumMg, original.sodiumMg);
      expect(copy.notes, original.notes);
      expect(copy.isDefault, original.isDefault);
    });
  });
}
