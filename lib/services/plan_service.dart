// lib/services/plan_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/plan.dart';

class PlanService {
  // Private constructor that takes a Firestore instance
  PlanService._internal(this._firestore);

  // Normal singleton used by the app
  static final PlanService instance =
      PlanService._internal(FirebaseFirestore.instance);

  // Factory for tests so we can pass a FakeFirebaseFirestore
  factory PlanService.forTests(FirebaseFirestore firestore) {
    return PlanService._internal(firestore);
  }

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _plansRef =>
      _firestore.collection('plans');

  Future<void> createPlan({
    required String userId,
    required String name,
    required int durationMinutes,
    required String patternType,
  }) async {
    await _plansRef.add({
      'userId': userId,
      'name': name,
      'durationMinutes': durationMinutes,
      'patternType': patternType,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Plan>> userPlansStream(String userId) {
    return _plansRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Plan.fromFirestore(doc)).toList(),
        );
  }

  Future<void> updatePlan({
    required String planId,
    required String name,
    required int durationMinutes,
    required String patternType,
  }) async {
    await _plansRef.doc(planId).update({
      'name': name,
      'durationMinutes': durationMinutes,
      'patternType': patternType,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePlan(String planId) async {
    await _plansRef.doc(planId).delete();
  }
}
