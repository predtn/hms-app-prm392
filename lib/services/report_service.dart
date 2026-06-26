import 'package:hms_app/models/dtos/revenue_report.dart';
import 'package:hms_app/models/fee.dart';
import 'package:hms_app/repositories/report_repository.dart';

class ReportService {
  ReportService({ReportRepository? repository})
    : _repository = repository ?? ReportRepository();

  final ReportRepository _repository;

  Future<RevenueReport> getRevenueReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final from = DateTime(fromDate.year, fromDate.month, fromDate.day).toUtc();
    final toExclusive = DateTime(
      toDate.year,
      toDate.month,
      toDate.day + 1,
    ).toUtc();

    final checkedOutBookings = await _repository.getCheckedOutBookingsBetween(
      fromInclusive: from,
      toExclusive: toExclusive,
    );
    final bookingIds = checkedOutBookings
        .map((row) => row['id'] as int)
        .toList();
    final checkoutDateByBookingId = {
      for (final row in checkedOutBookings)
        row['id'] as int: DateTime.parse(
          row['actual_check_out_date_time'] as String,
        ).toLocal(),
    };

    final feeRows = await _repository.getFeesByBookingIds(bookingIds);
    final dailyPoints = _buildDailyPoints(
      fromDate: fromDate,
      toDate: toDate,
      feeRows: feeRows,
      checkoutDateByBookingId: checkoutDateByBookingId,
    );

    final noShowRows = await _repository.getNoShowBookingsBetween(
      fromInclusive: from,
      toExclusive: toExclusive,
    );
    final rooms = await _repository.getRooms();
    final occupiedRooms = await _repository.getOccupiedRooms();

    return RevenueReport(
      fromDate: fromDate,
      toDate: toDate,
      roomRevenue: _sumFees(feeRows, FeeType.roomFee),
      serviceRevenue: _sumFees(feeRows, FeeType.service),
      extraRevenue: _sumFees(feeRows, FeeType.extraFee),
      dailyPoints: dailyPoints,
      checkedOutBookingCount: bookingIds.length,
      noShowCount: noShowRows.length,
      totalRoomCount: rooms.length,
      occupiedRoomCount: occupiedRooms
          .map((row) => row['room_id'] as int)
          .toSet()
          .length,
    );
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
