import 'dart:async';

import 'package:bonkguard_app/services/plan_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BG-212 Plan events persistence', () {
    test('createPlan stores events and reload returns same events', () async {
      final db = FakeFirebaseFirestore();
      final service = PlanService(firestore: db);

      const userId = 'user_123';

      final events = [
        {'minuteFromStart': 20, 'fuelItemId': 'maurten_160', 'servings': 1},
        {'minuteFromStart': 40, 'fuelItemId': 'gel_generic', 'servings': 1},
        {'minuteFromStart': 60, 'fuelItemId': 'maurten_320', 'servings': 1},
      ];

      final ref = await service.createPlan(
        userId: userId,
        name: 'Test Plan',
        durationMinutes: 90,
        patternType: 'fixed',
        patternFuelIds: const ['maurten_160', 'gel_generic', 'maurten_320'],
        intervalMinutes: 20,
        startOffsetMinutes: 20,
        carbsPerHour: 60,
        events: events,
      );
      

      // Read raw doc and confirm events exist
      final saved = await db.collection('plans').doc(ref.id).get();
      final data = saved.data()!;
      expect(data['events'], isA<List<dynamic>>());
      expect((data['events'] as List).length, 3);
      expect(data['schemaVersion'], 1);


      // Now read via stream mapping (Plan.fromFirestore)
      final completer = Completer<List<dynamic>>();
      late final StreamSubscription sub;

      sub = service.userPlansStream(userId).listen((plans) {
        if (plans.isNotEmpty) {
          final plan = plans.first;

          // Events exist and match in order/content
          expect(plan.events, isNotNull);
          expect(plan.events!.length, 3);

          expect(plan.events![0].minuteFromStart, 20);
          expect(plan.events![0].fuelItemId, 'maurten_160');
          expect(plan.events![0].servings, 1);

          expect(plan.events![1].minuteFromStart, 40);
          expect(plan.events![1].fuelItemId, 'gel_generic');
          expect(plan.events![1].servings, 1);

          expect(plan.events![2].minuteFromStart, 60);
          expect(plan.events![2].fuelItemId, 'maurten_320');
          expect(plan.events![2].servings, 1);

          completer.complete([]);
          sub.cancel();
        }
      });

      await completer.future;
    });

    test('updatePlan replaces events', () async {
      final db = FakeFirebaseFirestore();
      final service = PlanService(firestore: db);

      const userId = 'user_123';

      final ref = await service.createPlan(
        userId: userId,
        name: 'Test Plan',
        durationMinutes: 60,
        patternType: 'fixed',
        patternFuelIds: const ['a', 'b', 'c'],
        events: const [
          {'minuteFromStart': 20, 'fuelItemId': 'a', 'servings': 1},
        ],
      );

      await service.updatePlan(
        planId: ref.id,
        name: 'Test Plan',
        durationMinutes: 60,
        patternType: 'fixed',
        patternFuelIds: const ['a', 'b', 'c'],
        events: const [
          {'minuteFromStart': 15, 'fuelItemId': 'b', 'servings': 2},
          {'minuteFromStart': 45, 'fuelItemId': 'c', 'servings': 1},
        ],
      );

      final saved = await db.collection('plans').doc(ref.id).get();
      final data = saved.data()!;
      final savedEvents = (data['events'] as List).cast<Map<String, dynamic>>();

      expect(savedEvents.length, 2);
      expect(savedEvents[0]['minuteFromStart'], 15);
      expect(savedEvents[0]['fuelItemId'], 'b');
      expect(savedEvents[0]['servings'], 2);
    });

    test('plan stream returns empty for other user', () async {
      final db = FakeFirebaseFirestore();
      final service = PlanService(firestore: db);

      await service.createPlan(
        userId: 'user_A',
        name: 'Plan A',
        durationMinutes: 60,
        patternType: 'fixed',
        patternFuelIds: const ['a', 'b', 'c'],
        events: const [
          {'minuteFromStart': 10, 'fuelItemId': 'a', 'servings': 1},
        ],
      );

      final plansB = await service.userPlansStream('user_B').first;
      expect(plansB, isEmpty);
    });
  });
}
