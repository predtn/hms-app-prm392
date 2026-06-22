import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/booking_schedule_item.dart';
import 'package:hms_app/models/enums/booking_status.dart';
import 'package:hms_app/models/dtos/room_details.dart';
import 'package:hms_app/repositories/room_repository.dart';
import 'package:hms_app/views/receptionist/widgets/room_detail_card.dart';

class RoomDetailScreen extends StatefulWidget {
  final int roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late Future<RoomDetails> _roomDetailsFuture;
  late Future<List<BookingScheduleItem>> _bookingScheduleFuture;
  final _roomRepository = RoomRepository();

  @override
  void initState() {
    super.initState();
    _roomDetailsFuture = _roomRepository.getRoomDetails(widget.roomId);
    _bookingScheduleFuture = _roomRepository.getBookingSchedule(widget.roomId);
  }

  String _formatDateCompact(DateTime dt) {
    final toLocal = dt.toLocal();
    return '${toLocal.day.toString().padLeft(2, '0')}/${toLocal.month.toString().padLeft(2, '0')} ${toLocal.hour.toString().padLeft(2, '0')}:${toLocal.minute.toString().padLeft(2, '0')}';
  }

  double _calculateProgress(DateTime start, DateTime end) {
    final now = DateTime.now();
    if (now.isBefore(start)) return 0.0;
    if (now.isAfter(end)) return 1.0;

    final totalDuration = end.difference(start).inMilliseconds;
    final elapsedDuration = now.difference(start).inMilliseconds;

    if (totalDuration <= 0) return 1.0;
    return elapsedDuration / totalDuration;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RoomDetails>(
      future: _roomDetailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Lỗi')),
            body: Center(child: Text('Lỗi: ${snapshot.error}')),
          );
        } else if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Không tìm thấy')),
            body: const Center(child: Text('Không tìm thấy phòng')),
          );
        }

        final room = snapshot.data!;

        return Scaffold(
          // ── Title ─────────────────────────────────────────
          appBar: AppBar(title: Text('Phòng ${room.roomName}')),

          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Room detail ────────────────────────────────────
              // Room details section
              RoomDetailCard(room: room),

              // End Room details section
              const Divider(height: 32),

              FutureBuilder<List<BookingScheduleItem>>(
                future: _bookingScheduleFuture,
                builder: (context, scheduleSnapshot) {
                  if (scheduleSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (scheduleSnapshot.hasError) {
                    return Center(
                      child: Text('Lỗi tải lịch: ${scheduleSnapshot.error}'),
                    );
                  }

                  final schedules = scheduleSnapshot.data ?? [];
                  final checkedInList = schedules
                      .where((s) => s.status == BookingStatus.checkedIn)
                      .toList();
                  final currentGuest = checkedInList.isNotEmpty
                      ? checkedInList.first
                      : null;
                  final upcomingList = schedules
                      .where(
                        (s) =>
                            s.status != BookingStatus.checkedIn &&
                            s.status != BookingStatus.checkedOut,
                      )
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Current guests ───────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Khách đang ở',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () {
                              setState(() {
                                _bookingScheduleFuture = _roomRepository
                                    .getBookingSchedule(widget.roomId);
                              });
                            },
                          ),
                        ],
                      ),
                      if (currentGuest != null) ...[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundImage: currentGuest.customerAvatar != null
                                ? NetworkImage(currentGuest.customerAvatar!)
                                : null,
                            child: currentGuest.customerAvatar == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(currentGuest.customerName),
                          subtitle: Text(
                            '${_formatDateCompact(currentGuest.actualCheckInDateTime ?? currentGuest.checkInDateTime)} – ${_formatDateCompact(currentGuest.checkoutDateTime)}',
                          ),
                        ),
                        LinearProgressIndicator(
                          value: _calculateProgress(
                            currentGuest.actualCheckInDateTime ??
                                currentGuest.checkInDateTime,
                            currentGuest.checkoutDateTime,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.pushNamed(
                                context,
                                '/stay-management/${currentGuest.id}',
                              );
                              if (!context.mounted) return;
                              if (result == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Thao tác thành công!'),
                                  ),
                                );
                                setState(() {
                                  _bookingScheduleFuture = _roomRepository
                                      .getBookingSchedule(widget.roomId);
                                });
                              }
                            },
                            child: const Text('Quản lý lưu trú'),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Phòng trống',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ],

                      const Divider(height: 32),

                      // ── Upcoming bookings ──────────────────────────────────
                      const Text(
                        'Đặt phòng sắp tới',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (upcomingList.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Không có lịch đặt trước',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      else
                        ...upcomingList.map(
                          (s) => Card(
                            clipBehavior: Clip.hardEdge,
                            child: ListTile(
                              title: Text(s.customerName),
                              subtitle: Text(
                                '${_formatDateCompact(s.checkInDateTime)} – ${_formatDateCompact(s.checkoutDateTime)}',
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                              ),
                              onTap: () async {
                                final result = await Navigator.pushNamed(
                                  context,
                                  '/booking-details/${s.id}',
                                );
                                if (!context.mounted) return;
                                if (result == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Thao tác thành công!'),
                                    ),
                                  );
                                  setState(() {
                                    _bookingScheduleFuture = _roomRepository
                                        .getBookingSchedule(widget.roomId);
                                  });
                                }
                              },
                            ),
                          ),
                        ),

                      const Divider(height: 32),
                    ],
                  );
                },
              ),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  '/create-booking/${widget.roomId}',
                );
                if (!context.mounted) return;
                if (result == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đặt phòng thành công!')),
                  );
                  setState(() {
                    _bookingScheduleFuture = _roomRepository.getBookingSchedule(
                      widget.roomId,
                    );
                  });
                }
              },
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Đặt thêm lịch cho phòng này'),
            ),
          ),
        );
      },
    );
  }
}


