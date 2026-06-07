import 'package:flutter/material.dart';
import 'package:hms_app/models/user_profile.dart';
import 'package:hms_app/repositories/user_repository.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _repository = UserRepository();

  UserProfile? _userProfile;
  bool _isLoading = false;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;

  Future<void> fetchUserProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      _userProfile = await _repository.getCurrentUserProfile();
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearUser() {
    _userProfile = null;
    notifyListeners();
  }
}
