import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/billing_item.dart';
import 'package:hms_app/models/dtos/booking_details.dart';
import 'package:hms_app/models/dtos/booking_schedule_item.dart';
import 'package:hms_app/services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  BookingProvider({BookingService? service})
    : _service = service ?? BookingService();

  final BookingService _service;

  Future<void> createBooking({
    required int roomId,
    required String userId,
    required DateTime checkInDateTime,
    required DateTime checkOutDateTime,
    required bool checkInNow,
  }) {
    return _service.createBooking(
      roomId: roomId,
      userId: userId,
      checkInDateTime: checkInDateTime,
      checkOutDateTime: checkOutDateTime,
      checkInNow: checkInNow,
    );
  }

  Future<void> createBookings({
    required Iterable<int> roomIds,
    required String userId,
    required DateTime checkInDateTime,
    required DateTime checkOutDateTime,
    required bool checkInNow,
  }) {
    return _service.createBookings(
      roomIds: roomIds,
      userId: userId,
      checkInDateTime: checkInDateTime,
      checkOutDateTime: checkOutDateTime,
      checkInNow: checkInNow,
    );
  }

  Future<BookingScheduleItem> getBookingDetails(int bookingId) {
    return _service.getBookingDetails(bookingId);
  }

  Future<List<BookingScheduleItem>> getAllBookings() {
    return _service.getAllBookings();
  }

  Future<List<BookingScheduleItem>> getUpcomingCheckouts({
    Duration threshold = const Duration(minutes: 30),
  }) {
    return _service.getUpcomingCheckouts(threshold: threshold);
  }

  Future<List<BookingScheduleItem>> getTodayCheckins() {
    return _service.getTodayCheckins();
  }

  Future<List<BookingScheduleItem>> getBookingsByCustomerId(String userId) {
    return _service.getBookingsByCustomerId(userId);
  }

  Future<BookingDetails> getBookingDetailsWithServices(int bookingId) {
    return _service.getBookingDetailsWithServices(bookingId);
  }

  Future<void> deleteBooking(int bookingId) {
    return _service.deleteBooking(bookingId);
  }

  Future<void> checkIn(int bookingId, int roomId) {
    return _service.checkIn(bookingId, roomId);
  }

  Future<void> updateBooking({
    required int roomId,
    required int bookingId,
    required DateTime checkInDateTime,
    required DateTime checkOutDateTime,
  }) {
    return _service.updateBooking(
      roomId: roomId,
      bookingId: bookingId,
      checkInDateTime: checkInDateTime,
      checkOutDateTime: checkOutDateTime,
    );
  }

  Future<void> checkOut(int bookingId) {
    return _service.checkOut(bookingId);
  }

  Future<void> completeCheckout({
    required int bookingId,
    required List<BillingItem> billingItems,
  }) {
    return _service.completeCheckout(
      bookingId: bookingId,
      billingItems: billingItems,
    );
  }

  Future<void> markNoShow(int bookingId) {
    return _service.markNoShow(bookingId);
  }
}
