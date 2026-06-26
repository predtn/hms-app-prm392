import 'package:hms_app/models/dtos/booking_schedule_item.dart';
import 'package:hms_app/models/dtos/room_card_item.dart';
import 'package:hms_app/models/dtos/room_details.dart';
import 'package:hms_app/models/dtos/room_search_result.dart';
import 'package:hms_app/models/room.dart';
import 'package:hms_app/repositories/room_repository.dart';

class RoomService {
  RoomService({RoomRepository? repository})
    : _repository = repository ?? RoomRepository();

  final RoomRepository _repository;

  Future<List<RoomCardItem>> getRoomMap() => _repository.getRoomMap();

  Future<List<RoomCardItem>> getAvailableRoomMap() {
    return _repository.getAvailableRoomMap();
  }

  Future<List<RoomCardItem>> getUsingRoomMap() {
    return _repository.getUsingRoomMap();
  }

  Future<List<RoomCardItem>> getReservedRoomMap() {
    return _repository.getReservedRoomMap();
  }

  Future<List<Room>> fetchRooms() => _repository.fetchRooms();

  Future<void> createRoom(Room room) => _repository.createRoom(room);

  Future<void> deleteRoom(int id) => _repository.deleteRoom(id);

  Future<void> updateRoom(Room room) => _repository.updateRoom(room);

  Future<Room> getRoomById(int id) => _repository.getRoomById(id);

  Future<List<RoomSearchResult>> searchRooms({
    int? numberOfBed,
    List<String>? typeNames,
    DateTime? checkInDate,
    DateTime? checkOutDate,
  }) {
    return _repository.searchRooms(
      numberOfBed: numberOfBed,
      typeNames: typeNames,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
    );
  }

  Future<RoomDetails> getRoomDetails(int id) {
    return _repository.getRoomDetails(id);
  }

  Future<List<RoomDetails>> getRoomDetailsList(Iterable<int> ids) {
    return Future.wait(ids.map(getRoomDetails));
  }

  Future<List<BookingScheduleItem>> getBookingSchedule(int roomId) {
    return _repository.getBookingSchedule(roomId);
  }
}
