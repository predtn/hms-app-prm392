import 'package:hms_app/models/dtos/revenue_report.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getCheckedOutBookingsBetween({
    required DateTime fromInclusive,
    required DateTime toExclusive,
  }) async {
    final response = await _supabase
        .from('bookings')
        .select('id, actual_check_out_date_time')
        .eq('status', 'checked_out')
        .gte('actual_check_out_date_time', fromInclusive.toIso8601String())
        .lt('actual_check_out_date_time', toExclusive.toIso8601String());

    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getNoShowBookingsBetween({
    required DateTime fromInclusive,
    required DateTime toExclusive,
  }) async {
    final response = await _supabase
        .from('bookings')
        .select('id')
        .eq('status', 'no_show')
        .gte('check_in_date_time', fromInclusive.toIso8601String())
        .lt('check_in_date_time', toExclusive.toIso8601String());

    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getRooms() async {
    final response = await _supabase.from('rooms').select('id');

    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getOccupiedRooms() async {
    final response = await _supabase
        .from('bookings')
        .select('room_id')
        .eq('status', 'checked_in')
        .isFilter('actual_check_out_date_time', null);

    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<RevenueFeeRow>> getFeesByBookingIds(List<int> bookingIds) async {
    if (bookingIds.isEmpty) return [];

    final response = await _supabase
        .from('fees')
        .select('booking_id, total_price, type')
        .inFilter('booking_id', bookingIds);

    return (response as List)
        .map((row) => RevenueFeeRow.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
