import 'package:bonkguard_app/services/plan_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Plan Firestore schema', () {
    late FakeFirebaseFirestore firestore;
    late PlanService service;

    const userId = 'user123';

    setUp(() {
  firestore = FakeFirebaseFirestore();
  service = PlanService(firestore: firestore);
});

    test('createPlan writes patternFuelIds as an array and supports arrayContains', () async {
      await service.createPlan(
        userId: userId,
        name: 'Schema test plan',
        durationMinutes: 200,
        patternType: 'fixed',
        patternFuelIds: ['a', 'b', 'c'],
        carbsPerHour: 70,
        intervalMinutes: 15,
        startOffsetMinutes: 10,
      );

      final querySnap = await firestore
          .collection('plans')
          .where('userId', isEqualTo: userId)
          .where('patternFuelIds', arrayContains: 'b')
          .get();

      expect(querySnap.docs.length, 1);

      final data = querySnap.docs.first.data();
      expect(data['patternFuelIds'], isA<List<dynamic>>());
      expect((data['patternFuelIds'] as List).contains('b'), true);
      expect(data['carbsPerHour'], 70);
      expect(data['intervalMinutes'], 15);
      expect(data['startOffsetMinutes'], 10);
    });
  });
}
