// test/services/plan_service_test.dart
import 'package:bonkguard_app/models/plan.dart';
import 'package:bonkguard_app/services/plan_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlanService', () {
    late FakeFirebaseFirestore firestore;
    late PlanService service;
    const userId = 'user123';

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = PlanService.forTests(firestore);
    });

    test('createPlan writes a document with expected fields', () async {
      await service.createPlan(
        userId: userId,
        name: 'Test plan',
        durationMinutes: 120,
        patternType: 'fixed',
      );

      final snapshot = await firestore
          .collection('plans')
          .where('userId', isEqualTo: userId)
          .get();

      expect(snapshot.docs.length, 1);

      final data = snapshot.docs.first.data();
      expect(data['userId'], userId);
      expect(data['name'], 'Test plan');
      expect(data['durationMinutes'], 120);
      expect(data['patternType'], 'fixed');
    });

    test('userPlansStream returns mapped Plan objects', () async {
      final docRef = await firestore.collection('plans').add({
        'userId': userId,
        'name': 'Stream plan',
        'durationMinutes': 90,
        'patternType': 'fixed',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });

      final plans = await service.userPlansStream(userId).first;

      expect(plans.length, 1);

      final plan = plans.first;
      expect(plan.id, docRef.id);
      expect(plan.userId, userId);
      expect(plan.name, 'Stream plan');
      expect(plan.durationMinutes, 90);
      expect(plan.patternType, 'fixed');
    });

    test('updatePlan updates existing document', () async {
      final docRef = await firestore.collection('plans').add({
        'userId': userId,
        'name': 'Old name',
        'durationMinutes': 60,
        'patternType': 'fixed',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });

      await service.updatePlan(
        planId: docRef.id,
        name: 'New name',
        durationMinutes: 75,
        patternType: 'fixed',
      );

      final updated = await docRef.get();
      final data = updated.data() as Map<String, dynamic>;

      expect(data['name'], 'New name');
      expect(data['durationMinutes'], 75);
    });
  });
}
