enum RoomStatus { available, using }

class RoomCardItem {
  final int id;
  final String roomName;
  final String roomTypeName;
  final RoomStatus status;

  RoomCardItem({
    required this.id,
    required this.roomName,
    required this.roomTypeName,
    required this.status,
  });

  factory RoomCardItem.mapRoomCardItem(Map<String, dynamic> roomData) {
    final roomId = roomData['id'] as int;
    final roomName = roomData['room_name'] as String;
    final roomType = roomData['room_types'] as Map?;
    final typeName = roomType?['type_name'] as String? ?? '';

    final bookings = roomData['bookings'] as List? ?? [];

    final isUsing = bookings.any((b) {
      final status = b['status'];
      return status == 'checked_in';
    });

    return RoomCardItem(
      id: roomId,
      roomName: roomName,
      roomTypeName: typeName,
      status: isUsing ? RoomStatus.using : RoomStatus.available,
    );
  }

  @override
  String toString() {
    return 'RoomCardItem(id: $id, roomName: $roomName, roomTypeName: $roomTypeName, status: $status)';
  }
}
