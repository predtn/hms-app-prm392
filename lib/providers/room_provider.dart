import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/booking_schedule_item.dart';
import 'package:hms_app/models/dtos/room_card_item.dart';
import 'package:hms_app/models/dtos/room_details.dart';
import 'package:hms_app/models/dtos/room_search_result.dart';
import 'package:hms_app/models/room.dart';
import 'package:hms_app/services/room_service.dart';

class RoomProvider extends ChangeNotifier {
  RoomProvider({RoomService? service}) : _service = service ?? RoomService();

  final RoomService _service;

  Future<List<RoomCardItem>> getRoomMap() => _service.getRoomMap();

  Future<List<RoomCardItem>> getAvailableRoomMap() {
    return _service.getAvailableRoomMap();
  }

  Future<List<RoomCardItem>> getUsingRoomMap() {
    return _service.getUsingRoomMap();
  }

  Future<List<RoomCardItem>> getReservedRoomMap() {
    return _service.getReservedRoomMap();
  }

  Future<List<Room>> fetchRooms() => _service.fetchRooms();

  Future<void> createRoom(Room room) => _service.createRoom(room);

  Future<void> deleteRoom(int id) => _service.deleteRoom(id);

  Future<void> updateRoom(Room room) => _service.updateRoom(room);

  Future<Room> getRoomById(int id) => _service.getRoomById(id);

  Future<List<RoomSearchResult>> searchRooms({
    int? numberOfBed,
    List<String>? typeNames,
    DateTime? checkInDate,
    DateTime? checkOutDate,
  }) {
    return _service.searchRooms(
      numberOfBed: numberOfBed,
      typeNames: typeNames,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
    );
  }

  Future<RoomDetails> getRoomDetails(int id) {
    return _service.getRoomDetails(id);
  }

  Future<List<RoomDetails>> getRoomDetailsList(Iterable<int> ids) {
    return _service.getRoomDetailsList(ids);
  }

  Future<List<BookingScheduleItem>> getBookingSchedule(int roomId) {
    return _service.getBookingSchedule(roomId);
  }
}
