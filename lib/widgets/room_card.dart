import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/room_card_item.dart';
import 'package:hms_app/views/room_details_view.dart';

class RoomCard extends StatelessWidget {
  final RoomCardItem room;

  const RoomCard({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final isOccupied = room.status == RoomStatus.using;

    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RoomDetailScreen(roomId: room.id)),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(room.roomTypeName, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                room.roomName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 6,
                    color: isOccupied ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOccupied ? 'Đang SD' : 'Trống',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
