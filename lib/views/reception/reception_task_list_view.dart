import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/booking_schedule_item.dart';
import 'package:hms_app/models/enums/reception_task_type.dart';
import 'package:hms_app/repositories/booking_repository.dart';
import 'package:hms_app/views/reception/widgets/reception_task_widgets.dart';

class ReceptionTaskListView extends StatefulWidget {
  final String title;
  final String subtitle;
  final ReceptionTaskType type;
  final List<BookingScheduleItem> bookings;

  const ReceptionTaskListView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.bookings,
  });

  @override
  State<ReceptionTaskListView> createState() => _ReceptionTaskListViewState();
}

class _ReceptionTaskListViewState extends State<ReceptionTaskListView> {
  static const _soonThreshold = Duration(minutes: 30);

  final _bookingRepository = BookingRepository();
  final _phoneController = TextEditingController();
  late List<BookingScheduleItem> _bookings;
  String _phoneQuery = '';

  @override
  void initState() {
    super.initState();
    _bookings = widget.bookings;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isCheckinTask {
    return widget.type == ReceptionTaskType.upcomingCheckin ||
        widget.type == ReceptionTaskType.overdueCheckin;
  }

  List<BookingScheduleItem> get _filteredBookings {
    final query = _phoneQuery.trim();
    if (query.isEmpty) return _bookings;

    final normalizedQuery = _digitsOnly(query);
    return _bookings.where((booking) {
      final rawPhone = booking.customerPhone;
      final normalizedPhone = _digitsOnly(rawPhone);
      return rawPhone.contains(query) ||
          (normalizedQuery.isNotEmpty &&
              normalizedPhone.contains(normalizedQuery));
    }).toList();
  }

  Future<void> _reloadBookings() async {
    final allBookings = _isCheckinTask
        ? await _bookingRepository.getTodayCheckins()
        : await _bookingRepository.getUpcomingCheckouts(
            threshold: _soonThreshold,
          );

    if (!mounted) return;

    setState(() {
      _bookings = _filterBookingsByTaskType(allBookings);
    });
  }

  Future<void> _handleTaskUpdated(int bookingId) async {
    if (!mounted) return;

    setState(() {
      _bookings = _bookings.where((booking) => booking.id != bookingId).toList();
    });

    await _reloadBookings();
  }

  List<BookingScheduleItem> _filterBookingsByTaskType(
    List<BookingScheduleItem> bookings,
  ) {
    final now = DateTime.now();

    return bookings.where((booking) {
      switch (widget.type) {
        case ReceptionTaskType.upcomingCheckin:
          final checkin = booking.checkInDateTime.toLocal();
          final limit = now.add(_soonThreshold);
          return !checkin.isBefore(now) && !checkin.isAfter(limit);
        case ReceptionTaskType.overdueCheckin:
          return booking.checkInDateTime.toLocal().isBefore(now);
        case ReceptionTaskType.upcomingCheckout:
          return !booking.checkoutDateTime.toLocal().isBefore(now);
        case ReceptionTaskType.overdueCheckout:
          return booking.checkoutDateTime.toLocal().isBefore(now);
      }
    }).toList();
  }

  String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }

  String _timeStatus(DateTime target, String actionLabel) {
    final diff = target.toLocal().difference(DateTime.now());
    final absMinutes = diff.inMinutes.abs();

    if (diff.isNegative) {
      if (absMinutes < 60) return 'Quá hạn $absMinutes phút';
      final hours = absMinutes ~/ 60;
      final minutes = absMinutes % 60;
      return 'Quá hạn ${hours}h${minutes.toString().padLeft(2, '0')}';
    }

    if (diff.inMinutes <= 0) return 'Đến giờ $actionLabel';
    return 'Còn ${diff.inMinutes} phút';
  }

  Color _statusColor(BuildContext context, DateTime target) {
    final colorScheme = Theme.of(context).colorScheme;
    final diff = target.toLocal().difference(DateTime.now());

    if (diff.isNegative) return colorScheme.error;
    if (diff.inMinutes <= 10) return Colors.orange.shade800;
    return colorScheme.primary;
  }

  Future<void> _openBookingDetails(BookingScheduleItem booking) async {
    final result = await Navigator.pushNamed(
      context,
      '/booking-details/${booking.id}',
    );
    if (result == true) {
      await _handleTaskUpdated(booking.id);
    } else if (mounted) {
      await _reloadBookings();
    }
  }

  Future<void> _openStayManagement(BookingScheduleItem booking) async {
    final result = await Navigator.pushNamed(
      context,
      '/stay-management/${booking.id}',
    );
    if (result == true) {
      await _handleTaskUpdated(booking.id);
    } else if (mounted) {
      await _reloadBookings();
    }
  }

  Future<void> _openCheckout(BookingScheduleItem booking) async {
    final result = await Navigator.pushNamed(
      context,
      '/check-out/${booking.id}',
    );
    if (result == true) {
      await _handleTaskUpdated(booking.id);
    } else if (mounted) {
      await _reloadBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBookings;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _phoneQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Xóa tìm kiếm',
                      onPressed: () {
                        _phoneController.clear();
                        setState(() => _phoneQuery = '');
                      },
                      icon: const Icon(Icons.clear),
                    ),
              labelText: 'Tìm theo số điện thoại',
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _phoneQuery = value),
          ),
          const SizedBox(height: 16),
          TaskListSummary(
            shownCount: filtered.length,
            totalCount: _bookings.length,
          ),
          const SizedBox(height: 10),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: Text('Không tìm thấy trường hợp phù hợp.')),
            )
          else
            ...filtered.map((booking) {
              final targetTime = _isCheckinTask
                  ? booking.checkInDateTime
                  : booking.checkoutDateTime;
              final actionLabel = _isCheckinTask ? 'check-in' : 'checkout';
              final timeText = _isCheckinTask
                  ? 'Check-in dự kiến: ${_formatDateTime(targetTime)}'
                  : 'Checkout dự kiến: ${_formatDateTime(targetTime)}';

              return ReceptionTaskCard(
                booking: booking,
                timeText: timeText,
                statusText: _timeStatus(targetTime, actionLabel),
                statusColor: _statusColor(context, targetTime),
                primaryLabel: _isCheckinTask ? 'Check-in' : 'Checkout',
                primaryIcon: _isCheckinTask
                    ? Icons.login_outlined
                    : Icons.payments_outlined,
                onPrimary: _isCheckinTask
                    ? () => _openBookingDetails(booking)
                    : () => _openCheckout(booking),
                secondaryLabel: _isCheckinTask ? 'Chi tiết' : 'Gia hạn',
                secondaryIcon: _isCheckinTask
                    ? Icons.info_outline
                    : Icons.edit_calendar_outlined,
                onSecondary: _isCheckinTask
                    ? () => _openBookingDetails(booking)
                    : () => _openStayManagement(booking),
              );
            }),
        ],
      ),
    );
  }
}
