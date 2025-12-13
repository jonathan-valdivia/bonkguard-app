// lib/services/fuel_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';


import '../models/fuel_item.dart';
import '../data/default_fuels.dart'; 

class FuelService {
  FuelService._internal(this._firestore);

  static final FuelService instance =
      FuelService._internal(FirebaseFirestore.instance);

  factory FuelService.forTests(FirebaseFirestore firestore) {
    return FuelService._internal(firestore);
  }

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _fuelsRef =>
      _firestore.collection('fuels');

  /// One-time seeding of default fuels.
  /// Safe to call on every startup; it does nothing if defaults already exist.
  Future<void> seedDefaultFuelsIfEmpty() async {
    final existingDefaults = await _fuelsRef
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();

    // If we already have at least one default fuel, assume seeding is done.
    if (existingDefaults.docs.isNotEmpty) return;

    final batch = _firestore.batch();

    for (final fuel in DefaultFuels.all) {
      final docRef = _fuelsRef.doc(fuel.id); // stable ids
      batch.set(docRef, {
        'userId': null,
        'name': fuel.name,
        'brand': fuel.brand,
        'carbsPerServing': fuel.carbsPerServing,
        'caloriesPerServing': fuel.caloriesPerServing,
        'sodiumMg': fuel.sodiumMg,
        'notes': fuel.notes,
        'isDefault': true,
      });
    }

    await batch.commit();
  }

   /// Create a custom fuel item for a specific user.
  Future<void> createFuel({
    required String userId,
    required String name,
    required String brand,
    required int carbsPerServing,
    required int caloriesPerServing,
    required int sodiumMg,
    String? notes,
  }) async {
    await _fuelsRef.add({
      'userId': userId,
      'name': name,
      'brand': brand,
      'carbsPerServing': carbsPerServing,
      'caloriesPerServing': caloriesPerServing,
      'sodiumMg': sodiumMg,
      'notes': notes,
      'isDefault': false,
    });
  }

    /// 🔹 Update a custom fuel (non-default).
  Future<void> updateFuel({
    required String fuelId,
    required String name,
    required String brand,
    required int carbsPerServing,
    required int caloriesPerServing,
    required int sodiumMg,
    String? notes,
  }) async {
    await _fuelsRef.doc(fuelId).update({
      'name': name,
      'brand': brand,
      'carbsPerServing': carbsPerServing,
      'caloriesPerServing': caloriesPerServing,
      'sodiumMg': sodiumMg,
      'notes': notes,
    });
  }

  /// 🔹 Delete a custom fuel (non-default).
  Future<void> deleteFuel(String fuelId) async {
    await _fuelsRef.doc(fuelId).delete();
  }

  Stream<List<FuelItem>> streamUserFuels(String userId) async* {
     final defaultSnapshot = await _fuelsRef
        .where('isDefault', isEqualTo: true)
        .get();

    final defaultFuels = defaultSnapshot.docs
        .map(FuelItem.fromFirestore)
        .toList();

    yield* _fuelsRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final userFuels = snapshot.docs
          .map(FuelItem.fromFirestore)
          .toList();


    return [
      ...defaultFuels,
      ...userFuels,
    ];
  });
}
}