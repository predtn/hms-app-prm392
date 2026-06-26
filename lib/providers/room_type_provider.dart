import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/room_type_option.dart';
import 'package:hms_app/models/room_type.dart';
import 'package:hms_app/services/room_type_service.dart';

class RoomTypeProvider extends ChangeNotifier {
  RoomTypeProvider({RoomTypeService? service})
    : _service = service ?? RoomTypeService();

  final RoomTypeService _service;

  Future<void> createRoomType({
    required String typeName,
    required int numberOfBed,
    required int pricePerNight,
    String? description,
    String? addOn,
    String? imageUrl,
  }) {
    return _service.createRoomType(
      typeName: typeName,
      numberOfBed: numberOfBed,
      pricePerNight: pricePerNight,
      description: description,
      addOn: addOn,
      imageUrl: imageUrl,
    );
  }

  Future<List<RoomType>> getRoomTypes() => _service.getRoomTypes();

  Future<void> deleteRoomType(int id) => _service.deleteRoomType(id);

  Future<RoomType?> getRoomTypeById(int id) => _service.getRoomTypeById(id);

  Future<void> updateRoomType({
    required int id,
    required String typeName,
    required int numberOfBed,
    required int pricePerNight,
    String? description,
    String? addOn,
    String? imageUrl,
  }) {
    return _service.updateRoomType(
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
    return _service.getRoomTypeOptions();
  }
}
