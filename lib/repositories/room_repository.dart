import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/room_card_item.dart';
import 'package:hms_app/models/dtos/room_search_result.dart';
import 'package:hms_app/models/dtos/booking_schedule_item.dart';
import 'package:hms_app/models/dtos/room_details.dart';
import 'package:hms_app/models/room.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoomRepository {
  final _supabase = Supabase.instance.client;

  Future<List<RoomCardItem>> getRoomMap() async {
    final response = await _supabase.from('rooms').select('''
      id,
      room_name,
      room_types(type_name),
      bookings!left(
        status,
        actual_check_in_date_time,
        check_out_date_time
      )
    ''');

    var responseList = (response as List)
        .map((roomData) => RoomCardItem.mapRoomCardItem(roomData))
        .toList();
    debugPrint('┌────┬──────────┬─────────────┬─────────────┐');
    debugPrint('│ ID │ Room     │ Type        │ Status      │');
    debugPrint('├────┼──────────┼─────────────┼─────────────┤');
    for (final r in responseList) {
      debugPrint(
        '│ ${r.id.toString().padRight(3)}│ ${r.roomName.padRight(9)}│ ${r.roomTypeName.padRight(12)}│ ${r.status.name.padRight(12)}│',
      );
    }
    debugPrint('└────┴──────────┴─────────────┴─────────────┘');
    debugPrint('Total: ${responseList.length} rooms');
    return responseList;
  }

  Future<List<Room>> fetchRooms() async {
    final response = await _supabase
        .from('rooms')
        .select()
        .order('id', ascending: true);

    return (response as List).map((e) => Room.fromJson(e)).toList();
  }

  Future<void> createRoom(Room room) async {
    final data = Map<String, dynamic>.from(room.toJson());
    data.remove('id');
    await _supabase.from('rooms').insert(data);
  }

  Future<void> deleteRoom(int id) async {
    await _supabase.from('rooms').delete().eq('id', id);
  }

  Future<void> updateRoom(Room room) async {
    await _supabase.from('rooms').update(room.toJson()).eq('id', room.id);
  }

  Future<Room> getRoomById(int id) async {
    final response = await _supabase
        .from('rooms')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) {
      throw Exception('Không tìm thấy phòng');
    }
    return Room.fromJson(response);
  }

  Future<List<RoomSearchResult>> searchRooms({
    int? numberOfBed,
    List<String>? typeNames,
    DateTime? checkInDate,
    DateTime? checkOutDate,
  }) async {
    // 1. Get conflicting room IDs
    Set<int> conflictingRoomIds = {};
    if (checkInDate != null && checkOutDate != null) {
      final conflictingResponse = await _supabase
          .from('bookings')
          .select('room_id')
          .not('status', 'in', ['checked_out', 'no_show'])
          .lt('check_in_date_time', checkOutDate.toIso8601String())
          .gt('check_out_date_time', checkInDate.toIso8601String());

      conflictingRoomIds = (conflictingResponse as List<dynamic>)
          .map((row) => row['room_id'] as int)
          .toSet();
    }

    // 2. Get matching room types — include type_name for grouping
    var typeQuery = _supabase
        .from('room_types')
        .select('id, type_name, number_of_bed, image_url, description');

    if (numberOfBed != null) {
      typeQuery = typeQuery.eq('number_of_bed', numberOfBed);
    }

    if (typeNames != null && typeNames.isNotEmpty) {
      typeQuery = typeQuery.inFilter('type_name', typeNames);
    }

    final typeResponse = await typeQuery;
    final roomTypeMap = {
      for (final t in (typeResponse as List<dynamic>)) t['id'] as int: t,
    };

    if (roomTypeMap.isEmpty) return [];

    // 3. Query rooms by room_type_id, exclude conflicting
    var roomQuery = _supabase
        .from('rooms')
        .select('id, room_name, room_type_id')
        .inFilter('room_type_id', roomTypeMap.keys.toList());

    if (conflictingRoomIds.isNotEmpty) {
      roomQuery = roomQuery.not('id', 'in', conflictingRoomIds.toList());
    }

    final roomResponse = await roomQuery;

    // 4. Map to RoomSearchResult — wrap as { room_types: {...} } to match fromJson
    return (roomResponse as List<dynamic>).map((row) {
      final roomType = roomTypeMap[row['room_type_id'] as int]!;
      return RoomSearchResult.fromJson({
        'id': row['id'],
        'room_name': row['room_name'],
        'room_types': {
          'type_name': roomType['type_name'],
          'number_of_bed': roomType['number_of_bed'],
          'image_url': roomType['image_url'],
          'description': roomType['description'],
        },
      });
    }).toList();
  }

  Future<RoomDetails> getRoomDetails(int id) async {
    final response = await _supabase
        .from('rooms')
        .select('''
          id,
          room_name,
          floor,
          room_types(
            type_name,
            number_of_bed,
            price_per_night,
            description,
            image_url,
            add_on
          )
        ''')
        .eq('id', id)
        .maybeSingle();
    if (response == null) {
      throw Exception('Không tìm thấy phòng');
    }
    return RoomDetails.fromJson(response);
  }

  Future<List<BookingScheduleItem>> getBookingSchedule(int roomId) async {
    final response = await _supabase
        .from('bookings')
        .select('''
          id,
          room_id,
          user_profiles(full_name, avatar_url, phone),
          check_in_date_time,
          check_out_date_time,
          actual_check_out_date_time,
          actual_check_in_date_time,
          status
        ''')
        .eq('room_id', roomId)
        .neq('status', 'checked_out')
        .order('check_in_date_time', ascending: true);
    return (response as List)
        .map((e) => BookingScheduleItem.fromJson(e))
        .toList();
  }
}
