import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/booking_schedule_item.dart';
import 'package:hms_app/models/enums/booking_status.dart';
import 'package:hms_app/models/dtos/room_details.dart';
import 'package:hms_app/services/room_service.dart';
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
  final _roomService = RoomService();

  @override
  void initState() {
    super.initState();
    _roomDetailsFuture = _roomService.getRoomDetails(widget.roomId);
    _bookingScheduleFuture = _roomService.getBookingSchedule(widget.roomId);
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
    final color = Theme.of(context).colorScheme;

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
          backgroundColor: color.surface,
          appBar: AppBar(
            title: Text(
              'Chi tiết phòng ${room.roomName}',
              style: TextStyle(color: color.onSurface),
            ),
            centerTitle: true,
            backgroundColor: color.surface,
            iconTheme: IconThemeData(color: color.onSurface),
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // ── Room detail card ────────────────────────────────
              RoomDetailCard(room: room),

              const SizedBox(height: 24),

              FutureBuilder<List<BookingScheduleItem>>(
                future: _bookingScheduleFuture,
                builder: (context, scheduleSnapshot) {
                  if (scheduleSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (scheduleSnapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Lỗi tải lịch: ${scheduleSnapshot.error}',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
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
                      // ── Current guests section ───────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Khách đang lưu trú',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color.onSurface,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.refresh, color: color.primary),
                            onPressed: () {
                              setState(() {
                                _bookingScheduleFuture = _roomService
                                    .getBookingSchedule(widget.roomId);
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (currentGuest != null)
                        Card(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: color.outlineVariant.withAlpha(120),
                              width: 1,
                            ),
                          ),
                          color: color.surfaceContainerLow,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: color.primary.withAlpha(
                                        20,
                                      ),
                                      backgroundImage:
                                          currentGuest.customerAvatar != null &&
                                              currentGuest
                                                  .customerAvatar!
                                                  .isNotEmpty
                                          ? NetworkImage(
                                              currentGuest.customerAvatar!,
                                            )
                                          : null,
                                      child:
                                          currentGuest.customerAvatar == null ||
                                              currentGuest
                                                  .customerAvatar!
                                                  .isEmpty
                                          ? Icon(
                                              Icons.person,
                                              color: color.primary,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            currentGuest.customerName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'SDT: ${currentGuest.customerPhone}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: color.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withAlpha(20),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.redAccent.withAlpha(50),
                                        ),
                                      ),
                                      child: const Text(
                                        'Đang ở',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Check-in: ${_formatDateCompact(currentGuest.actualCheckInDateTime ?? currentGuest.checkInDateTime)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: color.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      'Check-out: ${_formatDateCompact(currentGuest.checkoutDateTime)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: color.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    minHeight: 6,
                                    value: _calculateProgress(
                                      currentGuest.actualCheckInDateTime ??
                                          currentGuest.checkInDateTime,
                                      currentGuest.checkoutDateTime,
                                    ),
                                    backgroundColor: color.onSurfaceVariant
                                        .withAlpha(30),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      color.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.tonalIcon(
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: () async {
                                      final result = await Navigator.pushNamed(
                                        context,
                                        '/stay-management/${currentGuest.id}',
                                      );
                                      if (!context.mounted) return;
                                      if (result == true) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Thao tác thành công!',
                                            ),
                                          ),
                                        );
                                        setState(() {
                                          _bookingScheduleFuture = _roomService
                                              .getBookingSchedule(
                                                widget.roomId,
                                              );
                                        });
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.manage_accounts_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Quản lý lưu trú'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: color.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: color.outlineVariant.withAlpha(120),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Phòng trống',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      'Sẵn sàng đón tiếp khách mới',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: color.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // ── Upcoming bookings section ──────────────────────────────────
                      Text(
                        'Đặt phòng sắp tới',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (upcomingList.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: color.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: color.outlineVariant.withAlpha(120),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 32,
                                color: color.onSurfaceVariant.withAlpha(100),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Không có lịch đặt trước',
                                style: TextStyle(
                                  color: color.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...upcomingList.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Card(
                              elevation: 0,
                              margin: EdgeInsets.zero,
                              color: color.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: color.outlineVariant.withAlpha(120),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: color.primary.withAlpha(15),
                                  backgroundImage:
                                      s.customerAvatar != null &&
                                          s.customerAvatar!.isNotEmpty
                                      ? NetworkImage(s.customerAvatar!)
                                      : null,
                                  child:
                                      s.customerAvatar == null ||
                                          s.customerAvatar!.isEmpty
                                      ? Icon(
                                          Icons.person_outline,
                                          color: color.primary,
                                        )
                                      : null,
                                ),
                                title: Text(
                                  s.customerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '${_formatDateCompact(s.checkInDateTime)} – ${_formatDateCompact(s.checkoutDateTime)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: color.onSurfaceVariant,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: color.onSurfaceVariant,
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
                                      _bookingScheduleFuture = _roomService
                                          .getBookingSchedule(widget.roomId);
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
                      _bookingScheduleFuture = _roomService.getBookingSchedule(
                        widget.roomId,
                      );
                    });
                  }
                },
                icon: const Icon(Icons.calendar_month_outlined, size: 20),
                label: const Text(
                  'Đặt lịch mới cho phòng này',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
