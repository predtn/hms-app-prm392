enum RoomStatus { available, reserved, using }

class RoomCardItem {
  final int id;
  final String roomName;
  final String roomTypeName;
  final String? imageUrl;
  final RoomStatus status;

  RoomCardItem({
    required this.id,
    required this.roomName,
    required this.roomTypeName,
    this.imageUrl,
    required this.status,
  });

  factory RoomCardItem.mapRoomCardItem(Map<String, dynamic> roomData) {
    final roomId = roomData['id'] as int;
    final roomName = roomData['room_name'] as String;
    final roomType = roomData['room_types'] as Map?;
    final typeName = roomType?['type_name'] as String? ?? '';
    final imageUrl = roomType?['image_url'] as String?;

    final bookings = roomData['bookings'] as List? ?? [];

    final now = DateTime.now().toUtc();

    final isUsing = bookings.any((b) {
      final status = b['status'];
      final actualCheckout = b['actual_check_out_date_time'];
      return _isCheckedIn(status) && actualCheckout == null;
    });

    final isReserved = bookings.any((b) {
      final status = b['status'];
      final checkout = DateTime.tryParse(
        b['check_out_date_time'] as String? ?? '',
      );

      return _isConfirmed(status) &&
          checkout != null &&
          checkout.toUtc().isAfter(now);
    });

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
    );
  }

  static bool _isCheckedIn(dynamic status) {
    return status == 'checked_in' || status == 'checkedIn';
  }

  static bool _isConfirmed(dynamic status) {
    return status == 'confirmed';
  }

  @override
  String toString() {
    return 'RoomCardItem(id: $id, roomName: $roomName, roomTypeName: $roomTypeName, status: $status)';
  }
}
