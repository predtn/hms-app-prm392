import 'package:hms_app/models/dtos/billing_item.dart';
import 'package:hms_app/models/dtos/booking_details.dart';
import 'package:hms_app/models/dtos/booking_schedule_item.dart';
import 'package:hms_app/models/enums/booking_status.dart';
import 'package:hms_app/repositories/booking_repository.dart';
import 'package:hms_app/repositories/fee_repository.dart';
import 'package:hms_app/repositories/user_repository.dart';

class BookingService {
  BookingService({
    BookingRepository? bookingRepository,
    UserRepository? userRepository,
    FeeRepository? feeRepository,
  }) : _bookingRepository = bookingRepository ?? BookingRepository(),
       _userRepository = userRepository ?? UserRepository(),
       _feeRepository = feeRepository ?? FeeRepository();

  final BookingRepository _bookingRepository;
  final UserRepository _userRepository;
  final FeeRepository _feeRepository;

  Future<void> createBooking({
    required int roomId,
    required String userId,
    required DateTime checkInDateTime,
    required DateTime checkOutDateTime,
    required bool checkInNow,
  }) async {
    final isAvailable = await _isBookingAvailable(
      roomId: roomId,
      checkInDateTime: checkInDateTime,
      checkOutDateTime: checkOutDateTime,
    );

    if (!isAvailable) {
      throw Exception('Phòng đã được đặt trong thời gian này!');
    }

    if (checkInNow && await _isRoomUsingNow(roomId: roomId)) {
      throw Exception('Phòng chưa được checkout!');
    }

    final userExists = await _userRepository.userExists(userId);
    if (!userExists) {
      throw Exception('Số điện thoại này chưa được đăng ký');
    }

    final scheduledCheckInDate = DateTime(
      checkInDateTime.year,
      checkInDateTime.month,
      checkInDateTime.day,
      14,
      0,
    );

    await _bookingRepository.insertBooking(
      roomId: roomId,
      userId: userId,
      scheduledCheckInDateTime: scheduledCheckInDate,
      actualCheckInDateTime: checkInNow ? checkInDateTime : null,
      checkOutDateTime: checkOutDateTime,
      status: checkInNow ? BookingStatus.checkedIn : BookingStatus.confirmed,
    );
  }

  Future<void> createBookings({
    required Iterable<int> roomIds,
    required String userId,
    required DateTime checkInDateTime,
    required DateTime checkOutDateTime,
    required bool checkInNow,
  }) async {
    for (final roomId in roomIds) {
      await createBooking(
        roomId: roomId,
        userId: userId,
        checkInDateTime: checkInDateTime,
        checkOutDateTime: checkOutDateTime,
        checkInNow: checkInNow,
      );
    }
  }

  Future<BookingScheduleItem> getBookingDetails(int bookingId) {
    return _bookingRepository.getBookingDetails(bookingId);
  }

  Future<List<BookingScheduleItem>> getAllBookings() {
    return _bookingRepository.getAllBookings();
  }

  Future<List<BookingScheduleItem>> getUpcomingCheckouts({
    Duration threshold = const Duration(minutes: 30),
  }) {
    return _bookingRepository.getUpcomingCheckouts(threshold: threshold);
  }

  Future<List<BookingScheduleItem>> getTodayCheckins() {
    return _bookingRepository.getTodayCheckins();
  }

  Future<List<BookingScheduleItem>> getBookingsByCustomerId(String userId) {
    return _bookingRepository.getBookingsByCustomerId(userId);
  }

  Future<BookingDetails> getBookingDetailsWithServices(int bookingId) {
    return _bookingRepository.getBookingDetailsWithServices(bookingId);
  }

  Future<void> deleteBooking(int bookingId) {
    return _bookingRepository.deleteBooking(bookingId);
  }

  Future<void> checkIn(int bookingId, int roomId) async {
    if (await _isRoomUsingNow(roomId: roomId)) {
      throw Exception('Phòng chưa được checkout!');
    }

    await _bookingRepository.checkIn(bookingId);
  }

  Future<void> updateBooking({
    required int roomId,
    required int bookingId,
    required DateTime checkInDateTime,
    required DateTime checkOutDateTime,
  }) async {
    final isAvailable = await _isBookingAvailable(
      roomId: roomId,
      checkInDateTime: checkInDateTime,
      checkOutDateTime: checkOutDateTime,
      bookingId: bookingId,
    );

    if (!isAvailable) {
      throw Exception('Phòng đã được đặt trong thời gian này!');
    }

    await _bookingRepository.updateBookingCheckOutDate(
      bookingId: bookingId,
      checkOutDateTime: checkOutDateTime,
    );
  }

  Future<void> checkOut(int bookingId) {
    return _bookingRepository.checkOut(bookingId);
  }

  Future<void> completeCheckout({
    required int bookingId,
    required List<BillingItem> billingItems,
  }) async {
    await _feeRepository.addFees(billingItems, bookingId);
    await _bookingRepository.checkOut(bookingId);
  }

  Future<void> markNoShow(int bookingId) {
    return _bookingRepository.markNoShow(bookingId);
  }

  Future<bool> _isBookingAvailable({
    required int roomId,
    required DateTime checkInDateTime,
    required DateTime checkOutDateTime,
    int? bookingId,
  }) async {
    final checkInUtc = checkInDateTime.toUtc();
    final checkOutUtc = checkOutDateTime.toUtc();

    final rows = await _bookingRepository.getPotentialOverlappingBookings(
      roomId: roomId,
      checkInUtc: checkInUtc,
      checkOutUtc: checkOutUtc,
      bookingId: bookingId,
    );

    final overlapping = rows.where((booking) {
      final actualCheckOut = booking['actual_check_out_date_time'];
      final scheduledCheckOut = booking['check_out_date_time'] as String;
      final effectiveCheckOut = actualCheckOut ?? scheduledCheckOut;
      final effectiveCheckOutDate = DateTime.parse(effectiveCheckOut).toUtc();

      return effectiveCheckOutDate.isAfter(checkInUtc);
    });

    return overlapping.isEmpty;
  }

  Future<bool> _isRoomUsingNow({required int roomId}) async {
    final rows = await _bookingRepository.getActiveCheckedInBookingsForRoom(
      roomId: roomId,
    );

    return rows.isNotEmpty;
  }
}
