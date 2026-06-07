import 'package:hms_app/models/enums/booking_status.dart';

class Booking {
  final int id;
  final int roomId;
  final DateTime checkInDateTime;
  final DateTime checkoutDateTime;
  final DateTime? actualCheckOutDateTime;
  final String? userId; // uuid stored as String
  final DateTime? actualCheckInDateTime;
  final BookingStatus status;

  Booking({
    required this.id,
    required this.roomId,
    required this.checkInDateTime,
    required this.checkoutDateTime,
    this.actualCheckOutDateTime,
    this.userId,
    this.actualCheckInDateTime,
    required this.status,
  });

  Booking copyWith({
    int? id,
    int? roomId,
    DateTime? checkInDateTime,
    DateTime? checkoutDateTime,
    DateTime? actualCheckOutDateTime,
    String? userId,
    DateTime? actualCheckInDateTime,
    BookingStatus? status,
  }) {
    return Booking(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      checkInDateTime: checkInDateTime ?? this.checkInDateTime,
      checkoutDateTime: checkoutDateTime ?? this.checkoutDateTime,
      actualCheckOutDateTime:
          actualCheckOutDateTime ?? this.actualCheckOutDateTime,
      userId: userId ?? this.userId,
      actualCheckInDateTime:
          actualCheckInDateTime ?? this.actualCheckInDateTime,
      status: status ?? this.status,
    );
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as int,
      roomId: json['room_id'] as int,
      checkInDateTime: DateTime.parse(json['check_in_date_time'] as String),
      checkoutDateTime: DateTime.parse(json['check_out_date_time'] as String),
      actualCheckOutDateTime: json['actual_check_out_date_time'] != null
          ? DateTime.parse(json['actual_check_out_date_time'] as String)
          : null,
      userId: json['user_id'] as String?,
      actualCheckInDateTime: json['actual_check_in_date_time'] != null
          ? DateTime.parse(json['actual_check_in_date_time'] as String)
          : null,
      status: json['status'] is String
          ? BookingStatusExtension.fromDatabaseValue(json['status'] as String)
          : BookingStatus.confirmed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'check_in_date_time': checkInDateTime.toUtc().toIso8601String(),
      'check_out_date_time': checkoutDateTime.toUtc().toIso8601String(),
      'actual_check_out_date_time': actualCheckOutDateTime
          ?.toUtc()
          .toIso8601String(),
      'user_id': userId,
      'actual_check_in_date_time': actualCheckInDateTime
          ?.toUtc()
          .toIso8601String(),
      'status': status.toDatabaseValue(),
    };
  }

  @override
  String toString() {
    return 'Booking(id: $id, roomId: $roomId, checkIn: $checkInDateTime, checkout: $checkoutDateTime, actualCheckout: $actualCheckOutDateTime, userId: $userId, actualCheckIn: $actualCheckInDateTime, status: ${status.toDatabaseValue()})';
  }
}
