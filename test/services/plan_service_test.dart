import 'package:bonkguard_app/services/plan_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlanService', () {
    late FakeFirebaseFirestore firestore;
    late PlanService service;

    const userId = 'user123';
    const fuelA = 'fuelA';
    const fuelB = 'fuelB';
    const fuelC = 'fuelC';

    setUp(() {
  firestore = FakeFirebaseFirestore();
  service = PlanService(firestore: firestore);
});

    test('userHasPlansUsingFuel returns false when no plans exist', () async {
      final result = await service.userHasPlansUsingFuel(
        userId: userId,
        fuelId: fuelA,
      );

      expect(result, false);
    });

    test('userHasPlansUsingFuel returns true when a plan references the fuelId', () async {
      // Create a plan that references fuelB
      await service.createPlan(
        userId: userId,
        name: 'My plan',
        durationMinutes: 180,
        patternType: 'fixed',
        patternFuelIds: [fuelA, fuelB, fuelC],
        carbsPerHour: 80,
        intervalMinutes: 20,
        startOffsetMinutes: 20,
      );

      final used = await service.userHasPlansUsingFuel(
        userId: userId,
        fuelId: fuelB,
      );

      expect(used, true);
    });

    test('userHasPlansUsingFuel returns false for other users plans', () async {
      // Plan belongs to someone else
      await service.createPlan(
        userId: 'otherUser',
        name: 'Other plan',
        durationMinutes: 120,
        patternType: 'fixed',
        patternFuelIds: [fuelA, fuelB, fuelC],
        carbsPerHour: 60,
        intervalMinutes: 20,
        startOffsetMinutes: 20,
      );

      final used = await service.userHasPlansUsingFuel(
        userId: userId,
        fuelId: fuelB,
      );

      expect(used, false);
    });

    test('userHasPlansUsingFuel returns false when fuelId is not in patternFuelIds', () async {
      await service.createPlan(
        userId: userId,
        name: 'My plan',
        durationMinutes: 180,
        patternType: 'fixed',
        patternFuelIds: [fuelA, fuelB, fuelC],
        carbsPerHour: 80,
        intervalMinutes: 20,
        startOffsetMinutes: 20,
      );

      final used = await service.userHasPlansUsingFuel(
        userId: userId,
        fuelId: 'fuelZ',
      );

      expect(used, false);
    });
  });
}
