import 'package:hms_app/models/dtos/room_type_option.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hms_app/models/room_type.dart';

class RoomTypeRepository {
  final _supabase = Supabase.instance.client;

  Future<void> createRoomType({
    required String typeName,
    required int numberOfBed,
    required int pricePerNight,
    String? description,
    String? addOn,
    String? imageUrl,
  }) async {
    await _supabase.from('room_types').insert({
      'type_name': typeName,
      'number_of_bed': numberOfBed,
      'price_per_night': pricePerNight,
      'description': description,
      'add_on': addOn,
      'image_url': imageUrl,
    });
  }

  Future<List<RoomType>> getRoomTypes() async {
    final response = await _supabase
        .from('room_types')
        .select()
        .order('id', ascending: true);

    return (response as List).map((json) => RoomType.fromJson(json)).toList();
  }

  Future<void> deleteRoomType(int id) async {
    await _supabase.from('room_types').delete().eq('id', id);
  }

  Future<RoomType?> getRoomTypeById(int id) async {
    final response = await _supabase
        .from('room_types')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return RoomType.fromJson(response);
  }

  Future<void> updateRoomType({
    required int id,
    required String typeName,
    required int numberOfBed,
    required int pricePerNight,
    String? description,
    String? addOn,
    String? imageUrl,
  }) async {
    await _supabase
        .from('room_types')
        .update({
          'type_name': typeName,
          'number_of_bed': numberOfBed,
          'price_per_night': pricePerNight,
          'description': description,
          'add_on': addOn,
          'image_url': imageUrl,
        })
        .eq('id', id);
  }

  Future<List<RoomTypeOption>> getRoomTypeOptions() async {
    final response = await _supabase
        .from('room_types')
        .select('id, type_name')
        .order('type_name');

    return (response as List).map((e) => RoomTypeOption.fromJson(e)).toList();
  }
}
