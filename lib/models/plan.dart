// lib/models/plan.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Plan {
  final String id;
  final String userId;
  final String name;
  final int durationMinutes;
  final String patternType;

  // 🔹 New fields for pattern support
  final int? carbsPerHour;        // target carbs per hour for this plan
  final int? intervalMinutes;     // e.g. 20 (fuel every 20 minutes)
  final int? startOffsetMinutes;  // e.g. 20 (first fuel at minute 20)
  final List<String>? patternFuelIds; // ordered list of FuelItem IDs: [A, B, C]

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
    this.createdAt,
    this.updatedAt,
  });

  /// Domain JSON (not Firestore-specific) – useful for tests / local storage
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
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Plan.fromJson(String id, Map<String, dynamic> json) {
    DateTime? parseDate(String? value) {
      if (value == null) return null;
      return DateTime.parse(value);
    }

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
      createdAt: parseDate(json['createdAt'] as String?),
      updatedAt: parseDate(json['updatedAt'] as String?),
    );
  }

  /// Firestore-specific factory
  factory Plan.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return Plan(
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
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
