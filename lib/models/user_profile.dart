// lib/models/user_profile.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final double? weightKg;
  final int carbsPerHour;
  final String units; // 'metric' or 'imperial'
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.email,
    this.weightKg,
    required this.carbsPerHour,
    required this.units,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'weightKg': weightKg,
      'carbsPerHour': carbsPerHour,
      'units': units,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserProfile.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: data['uid'] as String,
      email: data['email'] as String,
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      carbsPerHour: data['carbsPerHour'] as int? ?? 60,
      units: data['units'] as String? ?? 'metric',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
