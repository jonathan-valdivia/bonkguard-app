// lib/models/plan.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PlanEvent {
  final int minuteFromStart;
  final String fuelItemId;
  final int servings;

  PlanEvent({
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

  factory PlanEvent.fromJson(Map<String, dynamic> json) {
    return PlanEvent(
      minuteFromStart: (json['minuteFromStart'] ?? 0) as int,
      fuelItemId: json['fuelItemId'] as String? ?? '',
      servings: (json['servings'] ?? 1) as int,
    );
  }
}

class Plan {
  final int schemaVersion;
  final String id;
  final String userId;
  final String name;
  final int durationMinutes;
  final String patternType;

  final int? carbsPerHour;
  final int? intervalMinutes;
  final int? startOffsetMinutes;
  final List<String>? patternFuelIds;

  // ✅ NEW: generated fueling events persisted on the plan doc
  final List<PlanEvent>? events;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Plan({
    required this.id,
    required this.userId,
    required this.name,
    required this.durationMinutes,
    required this.patternType,
    this.carbsPerHour,
    this.intervalMinutes,
    this.startOffsetMinutes,
    this.patternFuelIds,
    this.events,
    this.createdAt,
    this.updatedAt,
    this.schemaVersion = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'durationMinutes': durationMinutes,
      'patternType': patternType,
      'carbsPerHour': carbsPerHour,
      'intervalMinutes': intervalMinutes,
      'startOffsetMinutes': startOffsetMinutes,
      'patternFuelIds': patternFuelIds,
      'events': events?.map((e) => e.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Plan.fromJson(String id, Map<String, dynamic> json) {
    DateTime? parseDate(String? value) {
      if (value == null) return null;
      return DateTime.parse(value);
    }

    final eventsJson = (json['events'] as List<dynamic>?)
        ?.cast<Map<String, dynamic>>();

    return Plan(
      id: id,
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      durationMinutes: (json['durationMinutes'] ?? 0) as int,
      patternType: json['patternType'] as String? ?? 'fixed',
      carbsPerHour: json['carbsPerHour'] as int?,
      intervalMinutes: json['intervalMinutes'] as int?,
      startOffsetMinutes: json['startOffsetMinutes'] as int?,
      patternFuelIds:
          (json['patternFuelIds'] as List<dynamic>?)?.cast<String>(),
      events: eventsJson?.map(PlanEvent.fromJson).toList(),
      createdAt: parseDate(json['createdAt'] as String?),
      updatedAt: parseDate(json['updatedAt'] as String?),
    );
  }

  factory Plan.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    final eventsJson = (data['events'] as List<dynamic>?)
        ?.cast<Map<String, dynamic>>();

    return Plan(
      schemaVersion: (data['schemaVersion'] as int?) ?? 1,
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      durationMinutes: (data['durationMinutes'] ?? 0) as int,
      patternType: data['patternType'] as String? ?? 'fixed',
      carbsPerHour: data['carbsPerHour'] as int?,
      intervalMinutes: data['intervalMinutes'] as int?,
      startOffsetMinutes: data['startOffsetMinutes'] as int?,
      patternFuelIds:
          (data['patternFuelIds'] as List<dynamic>?)?.cast<String>(),
      events: eventsJson?.map(PlanEvent.fromJson).toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
