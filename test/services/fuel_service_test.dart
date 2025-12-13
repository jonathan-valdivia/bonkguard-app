// test/services/fuel_service_test.dart
import 'package:bonkguard_app/data/default_fuels.dart';
//import 'package:bonkguard_app/models/fuel_item.dart';
import 'package:bonkguard_app/services/fuel_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FuelService', () {
    late FakeFirebaseFirestore firestore;
    late FuelService service;
    const userId = 'user123';

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = FuelService.forTests(firestore);
    });

    test('seedDefaultFuelsIfEmpty inserts default fuels when none exist', () async {
      // Initially empty
      final initialSnapshot =
          await firestore.collection('fuels').get();
      expect(initialSnapshot.docs.length, 0);

      await service.seedDefaultFuelsIfEmpty();

      final snapshot = await firestore
          .collection('fuels')
          .where('isDefault', isEqualTo: true)
          .get();

      // Should match the number of defaults defined in DefaultFuels
      expect(snapshot.docs.length, DefaultFuels.all.length);

      // Calling it again should not duplicate
      await service.seedDefaultFuelsIfEmpty();
      final snapshotAfter = await firestore
          .collection('fuels')
          .where('isDefault', isEqualTo: true)
          .get();

      expect(snapshotAfter.docs.length, DefaultFuels.all.length);
    });

    test('createFuel writes a custom fuel with correct fields', () async {
      await service.createFuel(
        userId: userId,
        name: 'Custom Gel',
        brand: 'MyBrand',
        carbsPerServing: 25,
        caloriesPerServing: 100,
        sodiumMg: 80,
        notes: 'Test notes',
      );

      final snapshot = await firestore
          .collection('fuels')
          .where('userId', isEqualTo: userId)
          .get();

      expect(snapshot.docs.length, 1);

      final data = snapshot.docs.first.data();
      expect(data['userId'], userId);
      expect(data['name'], 'Custom Gel');
      expect(data['brand'], 'MyBrand');
      expect(data['carbsPerServing'], 25);
      expect(data['caloriesPerServing'], 100);
      expect(data['sodiumMg'], 80);
      expect(data['notes'], 'Test notes');
      expect(data['isDefault'], false);
    });

    test('streamUserFuels returns default + user fuels', () async {
      // Seed defaults
      await service.seedDefaultFuelsIfEmpty();

      // Add one custom fuel for this user
      await service.createFuel(
        userId: userId,
        name: 'User Drink',
        brand: 'UserBrand',
        carbsPerServing: 60,
        caloriesPerServing: 240,
        sodiumMg: 300,
        notes: null,
      );

      // Get first emission from stream
      final fuels = await service.streamUserFuels(userId).first;

      // Should include all defaults + the one user fuel
      final defaultCount = DefaultFuels.all.length;
      expect(fuels.length, defaultCount + 1);

      final userFuels =
          fuels.where((f) => f.userId == userId).toList();
      final defaultFuels =
          fuels.where((f) => f.isDefault).toList();

      expect(defaultFuels.length, defaultCount);
      expect(userFuels.length, 1);

      final userFuel = userFuels.first;
      expect(userFuel.name, 'User Drink');
      expect(userFuel.brand, 'UserBrand');
      expect(userFuel.carbsPerServing, 60);
    });
  });
}
