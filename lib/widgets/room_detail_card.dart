import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/room_details.dart';
import 'package:hms_app/utils/format_vnd.dart';

class RoomDetailCard extends StatefulWidget {
  final RoomDetails room;

  const RoomDetailCard({super.key, required this.room});

  @override
  State<RoomDetailCard> createState() => _RoomDetailCardState();
}

class _RoomDetailCardState extends State<RoomDetailCard> {
  bool _addOnExpanded = true;

  bool get _hasAddOn =>
      widget.room.addOn != null && widget.room.addOn!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias, // makes InkWell ripple respect card border
      child: InkWell(
        onTap: _hasAddOn
            ? () => setState(() => _addOnExpanded = !_addOnExpanded)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Main info row ────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center, // chevron centered
              children: [
                // Thumbnail
                if (widget.room.imageUrl != null)
                  Image.network(
                    widget.room.imageUrl!,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    width: 110,
                    height: 110,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),

                // Text details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 0, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phòng ${widget.room.roomName} - ${widget.room.typeName}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.bed, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.room.numberOfBed} giường  •  Tầng ${widget.room.floor}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatVND(widget.room.pricePerNight)} VND/đêm',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        if (widget.room.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.room.description!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Chevron — vertically centered, tap handled by InkWell
                if (_hasAddOn)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AnimatedRotation(
                      turns: _addOnExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ),
              ],
            ),

            // ── Add-on panel ─────────────────────────────────────
            if (_hasAddOn && _addOnExpanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tiện ích kèm theo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.room.addOn!,
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
