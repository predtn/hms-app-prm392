enum RoomStatus { available, reserved, using }

class RoomCardItem {
  final int id;
  final String roomName;
  final String roomTypeName;
  final String? imageUrl;
  final RoomStatus status;
  final int numberOfBeds;
  final int upcomingBookingCount;

  RoomCardItem({
    required this.id,
    required this.roomName,
    required this.roomTypeName,
    this.imageUrl,
    required this.status,
    required this.numberOfBeds,
    required this.upcomingBookingCount,
  });

  factory RoomCardItem.mapRoomCardItem(Map<String, dynamic> roomData) {
    final roomId = roomData['id'] as int;
    final roomName = roomData['room_name'] as String;
    final roomType = roomData['room_types'] as Map?;
    final typeName = roomType?['type_name'] as String? ?? '';
    final imageUrl = roomType?['image_url'] as String?;
    final numberOfBeds = roomType?['number_of_bed'] as int? ?? 0;

    final bookings = roomData['bookings'] as List? ?? [];

    final isUsing = bookings.any((b) {
      final status = b['status'];
      final actualCheckout = b['actual_check_out_date_time'];
      return _isCheckedIn(status) && actualCheckout == null;
    });

    final upcomingBookings = bookings.where((b) {
      final status = b['status'] as String?;
      if (status == null) return false;
      final normalized = status.toLowerCase().replaceAll('_', '');
      return normalized != 'checkedout' && normalized != 'checkedin';
    }).toList();

    final isReserved = upcomingBookings.isNotEmpty;

    return RoomCardItem(
      id: roomId,
      roomName: roomName,
      roomTypeName: typeName,
      imageUrl: imageUrl,
      status: isUsing
          ? RoomStatus.using
          : isReserved
          ? RoomStatus.reserved
          : RoomStatus.available,
      numberOfBeds: numberOfBeds,
      upcomingBookingCount: upcomingBookings.length,
    );
  }

  static bool _isCheckedIn(dynamic status) {
    return status == 'checked_in' || status == 'checkedIn';
  }

  @override
  String toString() {
    return 'RoomCardItem(id: $id, roomName: $roomName, roomTypeName: $roomTypeName, status: $status, numberOfBeds: $numberOfBeds, upcomingBookingCount: $upcomingBookingCount)';
  }
}
