import 'package:cloud_firestore/cloud_firestore.dart';

class Plan {
  final String id;              // Firestore doc id
  final String userId;          // owner
  final String name;
  final int durationMinutes;    // total duration in minutes
  final String patternType;     // "fixed" for now
  final DateTime createdAt;
  final DateTime updatedAt;

  Plan({
    required this.id,
    required this.userId,
    required this.name,
    required this.durationMinutes,
    required this.patternType,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'durationMinutes': durationMinutes,
      'patternType': patternType,
      'createdAt': createdAt.toUtc(),
      'updatedAt': updatedAt.toUtc(),
    };
  }

  factory Plan.fromJson(String id, Map<String, dynamic> json) {
    return Plan(
      id: id,
      userId: json['userId'] as String,
      name: json['name'] as String,
      durationMinutes: json['durationMinutes'] as int,
      patternType: json['patternType'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }
}
