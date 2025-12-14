// lib/services/fueling_plan_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/fuel_item.dart';
import '../models/fuel_plan.dart';

class FuelingPlanService {
  FuelingPlanService._internal(this._firestore);

  static final FuelingPlanService instance =
      FuelingPlanService._internal(FirebaseFirestore.instance);

  factory FuelingPlanService.forTests(FirebaseFirestore firestore) {
    return FuelingPlanService._internal(firestore);
  }

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _plansRef =>
      _firestore.collection('fuelingPlans');

  /// Generate a fixed pattern fueling plan:
  /// A → B → C → repeat, using FuelItem IDs only in events.
  FuelingPlan generateFixedPatternPlan({
    required String userId,
    required Duration rideDuration,
    required int targetCarbsPerHour,
    required List<FuelItem> patternItems,
    required int intervalMinutes,
    required int startOffsetMinutes,
    String? name,
  }) {
    final events = <FuelingEvent>[];

    final totalMinutes = rideDuration.inMinutes;
    if (totalMinutes <= 0 || patternItems.isEmpty) {
      return FuelingPlan(
        id: '',
        userId: userId,
        rideDuration: rideDuration,
        targetCarbsPerHour: targetCarbsPerHour,
        events: events,
        name: name,
      );
    }

    var currentMinute = startOffsetMinutes;
    var patternIndex = 0;

    while (currentMinute <= totalMinutes) {
      final fuel = patternItems[patternIndex % patternItems.length];

      events.add(
        FuelingEvent(
          minuteFromStart: currentMinute,
          fuelItemId: fuel.id, // 🔹 store only the FuelItem ID
          servings: 1,
        ),
      );

      patternIndex += 1;
      currentMinute += intervalMinutes;
    }

    return FuelingPlan(
      id: '',
      userId: userId,
      rideDuration: rideDuration,
      targetCarbsPerHour: targetCarbsPerHour,
      events: events,
      name: name,
    );
  }

  /// Save a fueling plan document to Firestore.
  Future<void> savePlan(FuelingPlan plan) async {
    final data = {
      'userId': plan.userId,
      'name': plan.name,
      'rideDurationMinutes': plan.rideDuration.inMinutes,
      'targetCarbsPerHour': plan.targetCarbsPerHour,
      'events': plan.events.map((e) => e.toJson()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (plan.id.isEmpty) {
      await _plansRef.add(data);
    } else {
      await _plansRef.doc(plan.id).set(data, SetOptions(merge: true));
    }
  }

  /// Load all fueling plans for a user.
  Stream<List<FuelingPlan>> userFuelingPlansStream(String userId) {
    return _plansRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(FuelingPlan.fromFirestore).toList(),
        );
  }
}
