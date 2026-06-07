// fee.dart

enum FeeType { roomFee, service, extraFee }

extension FeeTypeExtension on FeeType {
  String toDatabaseValue() {
    switch (this) {
      case FeeType.roomFee:
        return 'room_fee';
      case FeeType.service:
        return 'service';
      case FeeType.extraFee:
        return 'extra_fee';
    }
  }

  static FeeType fromDatabaseValue(String dbValue) {
    switch (dbValue) {
      case 'room_fee':
        return FeeType.roomFee;
      case 'service':
        return FeeType.service;
      case 'extra_fee':
        return FeeType.extraFee;
      default:
        throw ArgumentError('Unknown FeeType: $dbValue');
    }
  }
}

class Fee {
  final int id;
  final int bookingId;
  final String title;
  final int totalPrice;
  final String? subtitle;
  final FeeType type;

  Fee({
    required this.id,
    required this.bookingId,
    required this.title,
    required this.totalPrice,
    this.subtitle,
    required this.type,
  });

  Fee copyWith({
    int? id,
    int? bookingId,
    String? title,
    int? totalPrice,
    String? subtitle,
    FeeType? type,
  }) {
    return Fee(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      title: title ?? this.title,
      totalPrice: totalPrice ?? this.totalPrice,
      subtitle: subtitle ?? this.subtitle,
      type: type ?? this.type,
    );
  }

  factory Fee.fromJson(Map<String, dynamic> json) {
    return Fee(
      id: json['id'] as int,
      bookingId: json['booking_id'] as int,
      title: json['title'] as String,
      totalPrice: json['total_price'] as int,
      subtitle: json['subtitle'] as String?,
      type: json['type'] is String
          ? FeeTypeExtension.fromDatabaseValue(json['type'] as String)
          : FeeType.extraFee,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'title': title,
      'total_price': totalPrice,
      'subtitle': subtitle,
      'type': type.toDatabaseValue(),
    };
  }

  @override
  String toString() {
    return 'Fee(id: $id, bookingId: $bookingId, title: $title, totalPrice: $totalPrice, subtitle: $subtitle, type: ${type.toDatabaseValue()})';
  }
}
