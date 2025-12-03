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
      carbsPerHour: 60, // default – we’ll make this editable later
      units: 'metric', // default – can be changed to 'imperial'
      createdAt: DateTime.now(),
    );

    await docRef.set(profile.toMap());
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromDoc(doc);
  }
}
