import '../models/plan.dart';
import '../models/fuel_item.dart';

class PlanGenerator {
  PlanGenerator._();
  static final PlanGenerator instance = PlanGenerator._();

  /// Generates events at a fixed interval, starting after [startOffsetMinutes],
  /// cycling through [patternFuelIds] in order.
  ///
  /// Example: pattern [A,B,C], interval 20:
  /// 20->A, 40->B, 60->C, 80->A, ...
  List<PlanEvent> generateFixedPatternEvents({
    required int durationMinutes,
    required int intervalMinutes,
    required int startOffsetMinutes,
    required List<String> patternFuelIds,
  }) {
    if (durationMinutes <= 0) return [];
    if (intervalMinutes <= 0) return [];
    if (startOffsetMinutes < 0) return [];
    if (patternFuelIds.isEmpty) return [];

    final events = <PlanEvent>[];

    int patternIndex = 0;
    for (int minute = startOffsetMinutes;
        minute <= durationMinutes;
        minute += intervalMinutes) {
      final fuelId = patternFuelIds[patternIndex % patternFuelIds.length];

      events.add(
        PlanEvent(
          minuteFromStart: minute,
          fuelItemId: fuelId,
          servings: 1,
        ),
      );

      patternIndex++;
    }

    return events;
  }

  int totalCarbs({
    required List<PlanEvent> events,
    required Map<String, FuelItem> fuelById,
  }) {
    int total = 0;
    for (final e in events) {
      final fuel = fuelById[e.fuelItemId];
      total += (fuel?.carbsPerServing ?? 0) * e.servings;
    }
    return total;
  }

  int? totalCalories({
    required List<PlanEvent> events,
    required Map<String, FuelItem> fuelById,
  }) {
    int total = 0;
    bool hasAny = false;

    for (final e in events) {
      final fuel = fuelById[e.fuelItemId];
      final cals = fuel?.caloriesPerServing;
      if (cals == null) continue;
      hasAny = true;
      total += cals * e.servings;
    }

    return hasAny ? total : null;
  }

  double avgCarbsPerHour({
    required int totalCarbs,
    required int durationMinutes,
  }) {
    if (durationMinutes <= 0) return 0;
    final hours = durationMinutes / 60.0;
    return totalCarbs / hours;
  }
}
