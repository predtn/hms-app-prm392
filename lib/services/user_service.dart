import 'package:hms_app/models/dtos/customer_short_detail.dart';
import 'package:hms_app/models/user_profile.dart';
import 'package:hms_app/repositories/user_repository.dart';

class UserService {
  UserService({UserRepository? repository})
    : _repository = repository ?? UserRepository();

  final UserRepository _repository;

  Future<UserProfile?> getCurrentUserProfile() {
    return _repository.getCurrentUserProfile();
  }

  Future<void> updateUserProfile({
    required String id,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) {
    return _repository.updateUserProfile(
      id: id,
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl,
    );
  }

  Future<List<CustomerShortDetail>> getAllCustomers() {
    return _repository.getAllCustomers();
  }

  Future<String> getNewlyCreatedCustomerId(
    String guestName,
    String guestPhone,
  ) {
    return _repository.getNewlyCreatedCustomerId(guestName, guestPhone);
  }
}
