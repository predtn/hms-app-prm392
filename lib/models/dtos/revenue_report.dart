import 'package:hms_app/models/fee.dart';

class RevenueReport {
  final DateTime fromDate;
  final DateTime toDate;
  final int roomRevenue;
  final int serviceRevenue;
  final int extraRevenue;
  final List<RevenueDailyPoint> dailyPoints;
  final int checkedOutBookingCount;
  final int noShowCount;
  final int totalRoomCount;
  final int occupiedRoomCount;

  const RevenueReport({
    required this.fromDate,
    required this.toDate,
    required this.roomRevenue,
    required this.serviceRevenue,
    required this.extraRevenue,
    required this.dailyPoints,
    required this.checkedOutBookingCount,
    required this.noShowCount,
    required this.totalRoomCount,
    required this.occupiedRoomCount,
  });

  int get totalRevenue => roomRevenue + serviceRevenue + extraRevenue;

  double get occupancyRate {
    if (totalRoomCount == 0) return 0;
    return occupiedRoomCount / totalRoomCount;
  }
}

class RevenueDailyPoint {
  final DateTime date;
  final int roomRevenue;
  final int serviceRevenue;
  final int extraRevenue;

  const RevenueDailyPoint({
    required this.date,
    required this.roomRevenue,
    required this.serviceRevenue,
    required this.extraRevenue,
  });

  int get totalRevenue => roomRevenue + serviceRevenue + extraRevenue;
}

class RevenueFeeRow {
  final int bookingId;
  final int totalPrice;
  final FeeType type;

  const RevenueFeeRow({
    required this.bookingId,
    required this.totalPrice,
    required this.type,
  });

  factory RevenueFeeRow.fromJson(Map<String, dynamic> json) {
    return RevenueFeeRow(
      bookingId: json['booking_id'] as int,
      totalPrice: json['total_price'] as int,
      type: FeeTypeExtension.fromDatabaseValue(json['type'] as String),
    );
  }
}
