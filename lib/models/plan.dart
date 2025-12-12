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
