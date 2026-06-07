import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/customer_short_detail.dart';
import 'package:hms_app/models/enums/user_role.dart';
import 'package:hms_app/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserRepository {
  final _supabase = Supabase.instance.client;

  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final data = await _supabase
        .from('user_profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  Future<void> updateUserProfile({
    required String id,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    await _supabase
        .from('user_profiles')
        .update({
          'full_name': fullName,
          'phone': phone,
          'avatar_url': avatarUrl,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<List<CustomerShortDetail>> getAllCustomers() async {
    final data = await _supabase
        .from('user_profiles')
        .select()
        .eq('role', UserRole.customer.label);
    debugPrint(data.toString());
    return data.map((e) => CustomerShortDetail.fromJson(e)).toList();
  }

  Future<String> getNewlyCreatedCustomerId(
    String guestName,
    String guestPhone,
  ) async {
    final guestEmail = '$guestPhone@hms.com';
    // Sign up creates auth.users → trigger auto-creates user_profiles row
    final authResponse = await _supabase.auth.signUp(
      email: guestEmail,
      password: '123123',
    );

    final userId = authResponse.user!.id;

    // Update the auto-created profile with guest info
    await _supabase
        .from('user_profiles')
        .update({
          'full_name': guestName,
          'phone': guestPhone,
          'role': UserRole.customer.label,
        })
        .eq('id', userId);

    return userId;
  }
}
