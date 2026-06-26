import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/customer_short_detail.dart';
import 'package:hms_app/models/user_profile.dart';
import 'package:hms_app/services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _service = UserService();

  UserProfile? _userProfile;
  bool _isLoading = false;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;

  Future<void> fetchUserProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      _userProfile = await _service.getCurrentUserProfile();
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile({
    required String id,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    await _service.updateUserProfile(
      id: id,
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl,
    );

    if (_userProfile?.id == id) {
      await fetchUserProfile();
    }
  }

  Future<List<CustomerShortDetail>> getAllCustomers() {
    return _service.getAllCustomers();
  }

  Future<String> getNewlyCreatedCustomerId(
    String guestName,
    String guestPhone,
  ) {
    return _service.getNewlyCreatedCustomerId(guestName, guestPhone);
  }

  void clearUser() {
    _userProfile = null;
    notifyListeners();
  }
}
