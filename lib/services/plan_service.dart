// lib/services/plan_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/plan.dart';




class PlanService {
    final FirebaseFirestore _db;

  PlanService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  static final PlanService instance = PlanService();

  static const int currentSchemaVersion = 1;

  CollectionReference<Map<String, dynamic>> get _plansRef =>
      _db.collection('plans');

  Stream<List<Plan>> userPlansStream(String userId) {
    return _plansRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map(Plan.fromFirestore).toList());
  }

  Future<DocumentReference<Map<String, dynamic>>> createPlan({
  required String userId,
  required String name,
  required int durationMinutes,
  required String patternType,
  required List<String> patternFuelIds,
  int intervalMinutes = 20,
  int startOffsetMinutes = 20,
  int? carbsPerHour,
  List<Map<String, dynamic>>? events,
}) async {
  return await _plansRef.add({
    'schemaVersion': currentSchemaVersion,
    'userId': userId,
    'name': name,
    'durationMinutes': durationMinutes,
    'patternType': patternType,
    'patternFuelIds': patternFuelIds,
    'intervalMinutes': intervalMinutes,
    'startOffsetMinutes': startOffsetMinutes,
    'carbsPerHour': carbsPerHour,
    'events': events,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

  Future<void> updatePlan({
  required String planId,
  required String name,
  required int durationMinutes,
  required String patternType,
  required List<String> patternFuelIds,
  int intervalMinutes = 20,
  int startOffsetMinutes = 20,
  int? carbsPerHour,
  List<Map<String, dynamic>>? events,
}) async {
  await _plansRef.doc(planId).update({
    'schemaVersion': currentSchemaVersion,
    'name': name,
    'durationMinutes': durationMinutes,
    'patternType': patternType,
    'patternFuelIds': patternFuelIds,
    'intervalMinutes': intervalMinutes,
    'startOffsetMinutes': startOffsetMinutes,
    'carbsPerHour': carbsPerHour,
    'events': events,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

Future<void> saveGeneratedEvents({
  required String planId,
  required List<Map<String, dynamic>> events,
}) async {
  await _plansRef.doc(planId).update({
    'events': events,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}




  Future<void> deletePlan(String planId) async {
    await _plansRef.doc(planId).delete();
  }

  

  Future<bool> userHasPlansUsingFuel({
  required String userId,
  required String fuelId,
}) async {
  final snapshot = await _plansRef
      .where('userId', isEqualTo: userId)
      .where('patternFuelIds', arrayContains: fuelId)
      .limit(1)
      .get();

  return snapshot.docs.isNotEmpty;
}


Future<void> migrateExistingPlansForUser(String userId) async {
    final snapshot =
        await _plansRef.where('userId', isEqualTo: userId).get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final updates = <String, dynamic>{};

      // Ensure patternType exists; fall back to 'fixed'
      if (!data.containsKey('patternType') || data['patternType'] == null) {
        updates['patternType'] = 'fixed';
      }

      // (We intentionally leave new fields like carbsPerHour, etc. null;
      //  the Plan model already treats them as optional.)

      if (updates.isNotEmpty) {
        await doc.reference.update(updates);
      }
    }
  }

}
