// lib/models/plan.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Plan {
  final String id;
  final String userId;
  final String name;
  final int durationMinutes;
  final String patternType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Plan({
    required this.id,
    required this.userId,
    required this.name,
    required this.durationMinutes,
    required this.patternType,
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
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
