
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plan.dart';

class PlanService {
  PlanService._();

  static final PlanService instance = PlanService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        //.orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Plan.fromFirestore(doc))
              .toList(),
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
}
