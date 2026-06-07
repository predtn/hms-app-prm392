import 'dart:core';

import 'package:hms_app/models/enums/booking_status.dart';

class BookingScheduleItem {
  final int id;
  final int roomId;
  final String? roomName;
  final String? customerAvatar;
  final String customerName;
  final String customerPhone;
  final DateTime checkInDateTime;
  final DateTime checkoutDateTime;
  final DateTime? actualCheckOutDateTime;
  final DateTime? actualCheckInDateTime;
  final BookingStatus status;

  BookingScheduleItem({
    required this.id,
    required this.roomId,
    this.roomName,
    required this.customerAvatar,
    required this.customerName,
    required this.customerPhone,
    required this.checkInDateTime,
    required this.checkoutDateTime,
    this.actualCheckOutDateTime,
    this.actualCheckInDateTime,
    required this.status,
  });

  factory BookingScheduleItem.fromJson(Map<String, dynamic> json) {
    return BookingScheduleItem(
      id: json['id'] as int,
      roomId: json['room_id'] as int,
      roomName: json['rooms'] != null
          ? json['rooms']['room_name'] as String?
          : null,
      customerAvatar: json['user_profiles']['avatar_url'] as String?,
      customerName: json['user_profiles']['full_name'] as String,
      customerPhone: json['user_profiles']['phone'] as String,
      checkInDateTime: DateTime.parse(json['check_in_date_time'] as String),
      checkoutDateTime: DateTime.parse(json['check_out_date_time'] as String),
      actualCheckOutDateTime: json['actual_check_out_date_time'] != null
          ? DateTime.parse(json['actual_check_out_date_time'] as String)
          : null,
      actualCheckInDateTime: json['actual_check_in_date_time'] != null
          ? DateTime.parse(json['actual_check_in_date_time'] as String)
          : null,
      status: json['status'] is String
          ? BookingStatusExtension.fromDatabaseValue(json['status'] as String)
          : BookingStatus.confirmed,
    );
  }
}
