import 'dart:convert';
import 'package:hms_app/utils/safe_parser.dart';

class Room {
  final int id;
  final String roomName;
  final int roomTypeId;
  final int floor;

  Room({
    required this.id,
    required this.roomName,
    required this.roomTypeId,
    required this.floor,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: parseInt(json['id']),
      roomName: json['room_name'] as String,
      roomTypeId: parseInt(json['room_type_id']),
      floor: parseInt(json['floor']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'room_name': roomName,
    'room_type_id': roomTypeId,
    'floor': floor,
  };

  // Convenience helpers
  static Room fromJsonString(String jsonString) =>
      Room.fromJson(json.decode(jsonString) as Map<String, dynamic>);

  String toJsonString() => json.encode(toJson());

  Room copyWith({int? id, String? roomName, int? roomTypeId, int? floor}) {
    return Room(
      id: id ?? this.id,
      roomName: roomName ?? this.roomName,
      roomTypeId: roomTypeId ?? this.roomTypeId,
      floor: floor ?? this.floor,
    );
  }

  @override
  String toString() {
    return 'Room(id: $id, roomName: $roomName, roomTypeId: $roomTypeId, floor: $floor)';
  }
}
