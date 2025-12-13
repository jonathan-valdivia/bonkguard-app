// lib/services/fuel_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:async/async.dart';

import '../models/fuel_item.dart';

class FuelService {
  FuelService._internal(this._firestore);

  // Normal singleton for the app
  static final FuelService instance =
      FuelService._internal(FirebaseFirestore.instance);

  // Factory for tests (we can inject FakeFirebaseFirestore later)
  factory FuelService.forTests(FirebaseFirestore firestore) {
    return FuelService._internal(firestore);
  }

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _fuelsRef =>
      _firestore.collection('fuels');

  /// Stream of fuels visible to this user:
  /// - default fuels (isDefault == true)
  /// - user-created fuels (userId == uid)
  Stream<List<FuelItem>> streamUserFuels(String userId) {
    final defaultFuelsStream = _fuelsRef
        .where('isDefault', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(FuelItem.fromFirestore).toList(),
        );

    final userFuelsStream = _fuelsRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(FuelItem.fromFirestore).toList(),
        );

    // Combine both streams into a single List<FuelItem>
    return StreamZip<List<FuelItem>>([
      defaultFuelsStream,
      userFuelsStream,
    ]).map((lists) {
      final defaults = lists[0];
      final userFuels = lists[1];
      return [...defaults, ...userFuels];
    });
  }
}
