// lib/services/fueling_plan_service.dart
import 'package:uuid/uuid.dart';

import '../models/fuel_item.dart';
import '../models/fuel_event.dart';
import '../models/fuel_plan.dart';

class FuelingPlanService {
  FuelingPlanService._();

  static final instance = FuelingPlanService._();

  final _uuid = const Uuid();

  /// Generate a fixed-pattern fueling plan:
  ///
  /// - patternItems: e.g. [A, B, C] will produce A → B → C → A → B → C...
  /// - intervalMinutes: how often to fuel (e.g. every 20 minutes)
  /// - startOffsetMinutes: first fueling event (e.g. at 20' into the ride)
  FuelingPlan generateFixedPatternPlan({
    required String userId,
    required Duration rideDuration,
    required int targetCarbsPerHour,
    required List<FuelItem> patternItems,
    int intervalMinutes = 20,
    int startOffsetMinutes = 20,
    String? name,
  }) {
    if (patternItems.isEmpty) {
      throw ArgumentError('patternItems cannot be empty');
    }

    final events = <FuelEvent>[];
    final totalMinutes = rideDuration.inMinutes;

    int minute = startOffsetMinutes;
    int patternIndex = 0;

    while (minute <= totalMinutes) {
      final item = patternItems[patternIndex];

      events.add(
        FuelEvent(minuteFromStart: minute, fuelItemId: item.id, servings: 1),
      );

      // Move ahead in time
      minute += intervalMinutes;

      // Move to next item in pattern (A → B → C → A → ...)
      patternIndex = (patternIndex + 1) % patternItems.length;
    }

    return FuelingPlan(
      id: _uuid.v4(), // temporary id, Firestore will give its own later
      userId: userId,
      createdAt: DateTime.now(),
      rideDuration: rideDuration,
      targetCarbsPerHour: targetCarbsPerHour,
      events: events,
      name: name,
    );
  }
}
