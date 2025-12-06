// lib/models/fueling_plan.dart

import 'fuel_event.dart';
import 'fuel_item.dart';

class FuelingPlan {
  final String id; // e.g. a Firestore doc id
  final String userId;

  final DateTime createdAt;

  /// Length of the ride this plan is for
  final Duration rideDuration;

  /// Target carbs per hour used to generate this plan
  final int targetCarbsPerHour;

  /// The actual sequence of fuel events
  final List<FuelEvent> events;

  /// Optional name or label e.g. "Saturday Long Ride"
  final String? name;

  FuelingPlan({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.rideDuration,
    required this.targetCarbsPerHour,
    required this.events,
    this.name,
  });

  /// Compute total carbs in the plan using the fuel library
  ///
  /// `fuelLibrary` is usually a Map from FuelItem.id → FuelItem
  int totalCarbs(Map<String, FuelItem> fuelLibrary) {
    int total = 0;
    for (final event in events) {
      final item = fuelLibrary[event.fuelItemId];
      if (item == null) continue;

      total += item.carbsPerServing * event.servings;
    }
    return total;
  }

  /// Compute total calories (if available)
  int? totalCalories(Map<String, FuelItem> fuelLibrary) {
    int total = 0;
    bool hasAnyCalories = false;

    for (final event in events) {
      final item = fuelLibrary[event.fuelItemId];
      if (item == null) continue;

      final caloriesPerServing = item.caloriesPerServing;
      if (caloriesPerServing == null) continue;

      hasAnyCalories = true;
      total += caloriesPerServing * event.servings;
    }

    if (!hasAnyCalories) return null;
    return total;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'rideDurationMinutes': rideDuration.inMinutes,
      'targetCarbsPerHour': targetCarbsPerHour,
      'events': events.map((e) => e.toMap()).toList(),
      'name': name,
    };
  }

  factory FuelingPlan.fromMap(String id, Map<String, dynamic> map) {
    final eventsList = (map['events'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map((e) => FuelEvent.fromMap(e))
        .toList();

    return FuelingPlan(
      id: id,
      userId: map['userId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      rideDuration: Duration(minutes: map['rideDurationMinutes'] as int),
      targetCarbsPerHour: map['targetCarbsPerHour'] as int,
      events: eventsList,
      name: map['name'] as String?,
    );
  }
}
