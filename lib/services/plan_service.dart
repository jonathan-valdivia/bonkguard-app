
import 'package:cloud_firestore/cloud_firestore.dart';

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
}
