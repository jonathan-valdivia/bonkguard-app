// lib/services/user_profile_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserProfileService {
  UserProfileService._();

  static final instance = UserProfileService._();

  final _usersCollection = FirebaseFirestore.instance.collection('users');

  Future<void> createUserProfileIfNotExists({
    required String uid,
    required String email,
  }) async {
    final docRef = _usersCollection.doc(uid);
    final doc = await docRef.get();

    if (doc.exists) {
      return;
    }

    final profile = UserProfile(
      uid: uid,
      email: email,
      weightKg: null,
      carbsPerHour: 60, // default
      units: 'metric', // default
      createdAt: DateTime.now(),
      onboardingComplete: false,
    );

    await docRef.set(profile.toMap());
  }

  /// New: always returns a profile; creates it if missing
  Future<UserProfile> getOrCreateUserProfile({
    required String uid,
    required String email,
  }) async {
    final docRef = _usersCollection.doc(uid);
    final doc = await docRef.get();

    if (doc.exists) {
      return UserProfile.fromDoc(doc);
    }

    // If no profile doc yet, create a default one
    final profile = UserProfile(
      uid: uid,
      email: email,
      weightKg: null,
      carbsPerHour: 60,
      units: 'metric',
      createdAt: DateTime.now(),
      onboardingComplete: false,
    );

    await docRef.set(profile.toMap());
    return profile;
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromDoc(doc);
  }

  Future<void> updateProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _usersCollection.doc(uid).update(data);
  }
}
