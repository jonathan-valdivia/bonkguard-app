// lib/state/user_profile_notifier.dart
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class UserProfileNotifier extends ChangeNotifier {
  UserProfile? _profile;

  UserProfile? get profile => _profile;
  bool get hasProfile => _profile != null;

  void setProfile(UserProfile? profile) {
    if (_profile == profile) return;
    _profile = profile;
    notifyListeners();
  }

  void updateProfile(UserProfile profile) {
    _profile = profile;
    notifyListeners();
  }

  void clear() {
    _profile = null;
    notifyListeners();
  }
}
