import 'package:hms_app/models/dtos/booking_details.dart';
import 'package:hms_app/models/dtos/booking_schedule_item.dart';
import 'package:hms_app/models/enums/booking_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingRepository {
  final _supabase = Supabase.instance.client;

  Future<void> createBooking({
    required int roomId,
    required String userId,
    required DateTime checkInDateTime,
    required DateTime checkOutDateTime,
    required bool checkInNow,
  }) async {
    // Validate booking
    if (!await _isBookingOverlap(
      roomId: roomId,
      checkInDateTime: checkInDateTime,
      checkOutDateTime: checkOutDateTime,
    )) {
      throw Exception('Phòng đã được đặt trong thời gian này!');
    }

    if (checkInNow && await _isRoomUsingNow(roomId: roomId)) {
      throw Exception('Phòng chưa được checkout!');
    }

    // Step 1: Find or create user
    var userProfile = await _supabase
        .from('user_profiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (userProfile == null) {
      throw Exception('Số điện thoại này chưa được đăng ký');
    }

    // Step 2: Create booking
    final checkInDate = DateTime(
      checkInDateTime.year,
      checkInDateTime.month,
      checkInDateTime.day,
      14,
      0,
    );
    await _supabase.from('bookings').insert({
      'room_id': roomId,
      'user_id': userId,
      'check_in_date_time': checkInDate.toUtc().toIso8601String(),
      'actual_check_in_date_time': checkInNow
          ? checkInDateTime.toUtc().toIso8601String()
          : null,
      'check_out_date_time': checkOutDateTime.toUtc().toIso8601String(),
      'status': checkInNow
          ? BookingStatus.checkedIn.name
          : BookingStatus.confirmed.name,
    });
  }

  Future<BookingScheduleItem> getBookingDetails(int bookingId) async {
    final response = await _supabase
        .from('bookings')
        .select('''
          id,
          room_id,
          rooms(room_name),
          user_profiles(full_name, avatar_url, phone),
          check_in_date_time,
          check_out_date_time,
          actual_check_out_date_time,
          actual_check_in_date_time,
          status
        ''')
        .eq('id', bookingId)
        .single();
    return BookingScheduleItem.fromJson(response);
  }

  Future<List<BookingScheduleItem>> getAllBookings() async {
    final response = await _supabase
        .from('bookings')
        .select('''
          id,
          room_id,
          rooms(room_name),
          user_profiles(full_name, avatar_url, phone),
          check_in_date_time,
          check_out_date_time,
          actual_check_out_date_time,
          actual_check_in_date_time,
          status
        ''')
        .order('check_in_date_time', ascending: false);

    return (response as List)
        .map((json) => BookingScheduleItem.fromJson(json))
        .toList();
  }

  Future<List<BookingScheduleItem>> getBookingsByCustomerId(
    String userId,
  ) async {
    final response = await _supabase
        .from('bookings')
        .select('''
          id,
          room_id,
          rooms(room_name),
          user_profiles(full_name, avatar_url, phone),
          check_in_date_time,
          check_out_date_time,
          actual_check_out_date_time,
          actual_check_in_date_time,
          status
        ''')
        .eq('user_id', userId)
        .order('check_in_date_time', ascending: false);

    return (response as List)
        .map((json) => BookingScheduleItem.fromJson(json))
        .toList();
  }

  Future<BookingDetails> getBookingDetailsWithServices(int bookingId) async {
    final booking = await _supabase
        .from('bookings')
        .select('''
          id,
          room_id,
          user_profiles(full_name, avatar_url, phone),
          check_in_date_time,
          check_out_date_time,
          actual_check_out_date_time,
          actual_check_in_date_time,
          status
        ''')
        .eq('id', bookingId)
        .single();
    final services = await _supabase
        .from('services')
        .select('''
          id,
          name,
          price_per_unit,
          description,
          unit,
          image_url,
          status,
          service_usage!left(
            booking_id,
            quantity
          )
        ''')
        .eq('status', true)
        .eq('service_usage.booking_id', bookingId);

    return BookingDetails.fromJson(booking, services);
  }

  Future<void> deleteBooking(int bookingId) async {
    await _supabase.from('bookings').delete().eq('id', bookingId);
  }

  Future<void> checkIn(int bookingId, int roomId) async {
    if (await _isRoomUsingNow(roomId: roomId)) {
      throw Exception('Phòng chưa được checkout!');
    }
    await _supabase
        .from('bookings')
        .update({
          'status': BookingStatus.checkedIn.name,
          'actual_check_in_date_time': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', bookingId);
  }

  Future<void> updateBooking({
    required int roomId,
    required int bookingId,
    required DateTime checkInDateTime,
    required DateTime checkOutDateTime,
  }) async {
    if (!await _isBookingOverlap(
      roomId: roomId,
      checkInDateTime: checkInDateTime,
      checkOutDateTime: checkOutDateTime,
      bookingId: bookingId,
    )) {
      throw Exception("Phòng đã được đặt trong thời gian này!");
    }
    await _supabase
        .from("bookings")
        .update({
          "check_out_date_time": checkOutDateTime.toUtc().toIso8601String(),
        })
        .eq('id', bookingId);
  }

  Future<void> checkOut(int bookingId) async {
    await _supabase
        .from('bookings')
        .update({
          'status': BookingStatus.checkedOut.name,
          'actual_check_out_date_time': DateTime.now()
              .toUtc()
              .toIso8601String(),
        })
        .eq('id', bookingId);
  }

  /// --------------------------------------------------------------------
  /// Helper functions check room is ok to book in this time

  Future<bool> _isBookingOverlap({
    required int roomId,
    required DateTime checkInDateTime,
    required DateTime checkOutDateTime,
    int? bookingId,
  }) async {
    // Ensure we always send UTC to Postgres, regardless of local timezone
    final checkInUtc = checkInDateTime.toUtc();
    final checkOutUtc = checkOutDateTime.toUtc();

    var query = _supabase
        .from('bookings')
        .select()
        .eq('room_id', roomId)
        .neq('status', 'no_show')
        .or(
          'actual_check_out_date_time.is.null,actual_check_out_date_time.gt.${checkInUtc.toIso8601String()}',
        )
        .lt('check_in_date_time', checkOutUtc.toIso8601String());

    if (bookingId != null) {
      query = query.neq('id', bookingId);
    }

    final response = await query;

    final overlapping = (response as List).where((booking) {
      final actualCheckOut = booking['actual_check_out_date_time'];
      final scheduledCheckOut = booking['check_out_date_time'] as String;

      final effectiveCheckOut = actualCheckOut ?? scheduledCheckOut;

      // Parse and convert to UTC for safe comparison
      final effectiveCheckOutDate = DateTime.parse(effectiveCheckOut).toUtc();

      return effectiveCheckOutDate.isAfter(checkInUtc);
    }).toList();

    return overlapping.isEmpty;
  }

  Future<bool> _isRoomUsingNow({required int roomId}) async {
    final response = await _supabase
        .from('bookings')
        .select()
        .eq('room_id', roomId)
        .eq('status', 'checked_in')
        .isFilter('actual_check_out_date_time', null);
    return (response as List).isNotEmpty;
  }
}
