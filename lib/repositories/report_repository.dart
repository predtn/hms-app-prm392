import 'package:hms_app/models/dtos/revenue_report.dart';
import 'package:hms_app/models/fee.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportRepository {
  final _supabase = Supabase.instance.client;

  Future<RevenueReport> getRevenueReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final from = DateTime(
      fromDate.year,
      fromDate.month,
      fromDate.day,
    ).toUtc();
    final toExclusive = DateTime(
      toDate.year,
      toDate.month,
      toDate.day + 1,
    ).toUtc();

    final checkedOutBookings = await _supabase
        .from('bookings')
        .select('id, actual_check_out_date_time')
        .eq('status', 'checked_out')
        .gte('actual_check_out_date_time', from.toIso8601String())
        .lt('actual_check_out_date_time', toExclusive.toIso8601String());

    final checkedOutRows = checkedOutBookings as List;
    final bookingIds = checkedOutRows
        .map((row) => row['id'] as int)
        .toList();
    final checkoutDateByBookingId = {
      for (final row in checkedOutRows)
        row['id'] as int: DateTime.parse(
          row['actual_check_out_date_time'] as String,
        ).toLocal(),
    };

    final feeRows = bookingIds.isEmpty
        ? <RevenueFeeRow>[]
        : await _getFeesByBookingIds(bookingIds);
    final dailyPoints = _buildDailyPoints(
      fromDate: fromDate,
      toDate: toDate,
      feeRows: feeRows,
      checkoutDateByBookingId: checkoutDateByBookingId,
    );

    final noShowRows = await _supabase
        .from('bookings')
        .select('id')
        .eq('status', 'no_show')
        .gte('check_in_date_time', from.toIso8601String())
        .lt('check_in_date_time', toExclusive.toIso8601String());

    final rooms = await _supabase.from('rooms').select('id');
    final occupiedRooms = await _supabase
        .from('bookings')
        .select('room_id')
        .eq('status', 'checked_in')
        .isFilter('actual_check_out_date_time', null);

    return RevenueReport(
      fromDate: fromDate,
      toDate: toDate,
      roomRevenue: _sumFees(feeRows, FeeType.roomFee),
      serviceRevenue: _sumFees(feeRows, FeeType.service),
      extraRevenue: _sumFees(feeRows, FeeType.extraFee),
      dailyPoints: dailyPoints,
      checkedOutBookingCount: bookingIds.length,
      noShowCount: (noShowRows as List).length,
      totalRoomCount: (rooms as List).length,
      occupiedRoomCount: (occupiedRooms as List)
          .map((row) => row['room_id'] as int)
          .toSet()
          .length,
    );
  }

  Future<List<RevenueFeeRow>> _getFeesByBookingIds(List<int> bookingIds) async {
    final response = await _supabase
        .from('fees')
        .select('booking_id, total_price, type')
        .inFilter('booking_id', bookingIds);

    return (response as List)
        .map((row) => RevenueFeeRow.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  int _sumFees(List<RevenueFeeRow> rows, FeeType type) {
    return rows
        .where((row) => row.type == type)
        .fold(0, (sum, row) => sum + row.totalPrice);
  }

  List<RevenueDailyPoint> _buildDailyPoints({
    required DateTime fromDate,
    required DateTime toDate,
    required List<RevenueFeeRow> feeRows,
    required Map<int, DateTime> checkoutDateByBookingId,
  }) {
    final buckets = <DateTime, _RevenueBucket>{};
    var day = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final lastDay = DateTime(toDate.year, toDate.month, toDate.day);

    while (!day.isAfter(lastDay)) {
      buckets[day] = _RevenueBucket();
      day = day.add(const Duration(days: 1));
    }

    for (final row in feeRows) {
      final checkoutDate = checkoutDateByBookingId[row.bookingId];
      if (checkoutDate == null) continue;

      final bucketKey = DateTime(
        checkoutDate.year,
        checkoutDate.month,
        checkoutDate.day,
      );
      buckets[bucketKey]?.add(row);
    }

    return buckets.entries
        .map(
          (entry) => RevenueDailyPoint(
            date: entry.key,
            roomRevenue: entry.value.roomRevenue,
            serviceRevenue: entry.value.serviceRevenue,
            extraRevenue: entry.value.extraRevenue,
          ),
        )
        .toList();
  }
}

class _RevenueBucket {
  int roomRevenue = 0;
  int serviceRevenue = 0;
  int extraRevenue = 0;

  void add(RevenueFeeRow row) {
    switch (row.type) {
      case FeeType.roomFee:
        roomRevenue += row.totalPrice;
        break;
      case FeeType.service:
        serviceRevenue += row.totalPrice;
        break;
      case FeeType.extraFee:
        extraRevenue += row.totalPrice;
        break;
    }
  }
}
