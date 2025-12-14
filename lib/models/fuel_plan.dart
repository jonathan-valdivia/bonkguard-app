// lib/models/fuel_plan.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'fuel_item.dart';

class FuelingEvent {
  final int minuteFromStart;
  final String fuelItemId;
  final int servings;

  FuelingEvent({
    required this.minuteFromStart,
    required this.fuelItemId,
    required this.servings,
  });

  Map<String, dynamic> toJson() {
    return {
      'minuteFromStart': minuteFromStart,
      'fuelItemId': fuelItemId,
      'servings': servings,
    };
  }

  factory FuelingEvent.fromJson(Map<String, dynamic> json) {
    return FuelingEvent(
      minuteFromStart: (json['minuteFromStart'] ?? 0) as int,
      fuelItemId: json['fuelItemId'] as String? ?? '',
      servings: (json['servings'] ?? 1) as int,
    );
  }
}

class FuelingPlan {
  final String id;
  final String userId;
  final Duration rideDuration;
  final int targetCarbsPerHour;
  final List<FuelingEvent> events;
  final String? name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FuelingPlan({
    required this.id,
    required this.userId,
    required this.rideDuration,
    required this.targetCarbsPerHour,
    required this.events,
    this.name,
    this.createdAt,
    this.updatedAt,
  });

  /// Calculate total carbs for the plan using provided FuelItems.
  /// We rely ONLY on fuelItemId -> FuelItem mapping (no legacy FuelLibrary).
  int totalCarbs(Iterable<FuelItem> fuels) {
    final fuelById = {
      for (final f in fuels) f.id: f,
    };

    var total = 0;
    for (final event in events) {
      final fuel = fuelById[event.fuelItemId];
      if (fuel == null) continue;
      total += fuel.carbsPerServing * event.servings;
    }
    return total;
  }

  /// Calculate total calories if we have calorie data.
  int? totalCalories(Iterable<FuelItem> fuels) {
    final fuelById = {
      for (final f in fuels) f.id: f,
    };

    var total = 0;
    var hasAny = false;

    for (final event in events) {
      final fuel = fuelById[event.fuelItemId];
      if (fuel == null) continue;
      hasAny = true;
      total += fuel.caloriesPerServing * event.servings;
    }

    return hasAny ? total : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'rideDurationMinutes': rideDuration.inMinutes,
      'targetCarbsPerHour': targetCarbsPerHour,
      'name': name,
      'events': events.map((e) => e.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory FuelingPlan.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final eventsJson = (data['events'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return FuelingPlan(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String?,
      rideDuration: Duration(
        minutes: (data['rideDurationMinutes'] ?? 0) as int,
      ),
      targetCarbsPerHour: (data['targetCarbsPerHour'] ?? 0) as int,
      events: eventsJson.map(FuelingEvent.fromJson).toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
