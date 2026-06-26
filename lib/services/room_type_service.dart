import 'package:hms_app/models/dtos/room_type_option.dart';
import 'package:hms_app/models/room_type.dart';
import 'package:hms_app/repositories/room_type_repository.dart';

class RoomTypeService {
  RoomTypeService({RoomTypeRepository? repository})
    : _repository = repository ?? RoomTypeRepository();

  final RoomTypeRepository _repository;

  Future<void> createRoomType({
    required String typeName,
    required int numberOfBed,
    required int pricePerNight,
    String? description,
    String? addOn,
    String? imageUrl,
  }) {
    return _repository.createRoomType(
      typeName: typeName,
      numberOfBed: numberOfBed,
      pricePerNight: pricePerNight,
      description: description,
      addOn: addOn,
      imageUrl: imageUrl,
    );
  }

  Future<List<RoomType>> getRoomTypes() => _repository.getRoomTypes();

  Future<void> deleteRoomType(int id) => _repository.deleteRoomType(id);

  Future<RoomType?> getRoomTypeById(int id) => _repository.getRoomTypeById(id);

  Future<void> updateRoomType({
    required int id,
    required String typeName,
    required int numberOfBed,
    required int pricePerNight,
    String? description,
    String? addOn,
    String? imageUrl,
  }) {
    return _repository.updateRoomType(
      id: id,
      typeName: typeName,
      numberOfBed: numberOfBed,
      pricePerNight: pricePerNight,
      description: description,
      addOn: addOn,
      imageUrl: imageUrl,
    );
  }

  Future<List<RoomTypeOption>> getRoomTypeOptions() {
    return _repository.getRoomTypeOptions();
  }
}
