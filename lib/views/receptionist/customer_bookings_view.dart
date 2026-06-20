import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/booking_schedule_item.dart';
import 'package:hms_app/models/dtos/customer_short_detail.dart';
import 'package:hms_app/models/enums/booking_status.dart';
import 'package:hms_app/repositories/booking_repository.dart';

class CustomerBookingsView extends StatefulWidget {
  final CustomerShortDetail customer;

  const CustomerBookingsView({super.key, required this.customer});

  @override
  State<CustomerBookingsView> createState() => _CustomerBookingsViewState();
}

class _CustomerBookingsViewState extends State<CustomerBookingsView> {
  late Future<List<BookingScheduleItem>> _bookingsFuture;
  final _bookingRepository = BookingRepository();

  // Index corresponding to BookingStatus order:
  // 0 → confirmed, 1 → checkedIn, 2 → checkedOut, 3 → noShow
  int _selectedTabIndex = 0;

  static const _tabLabels = [
    'Đã đặt cọc',
    'Đang ở',
    'Đã trả phòng',
    'Vắng mặt',
  ];

  static const _tabStatuses = [
    BookingStatus.confirmed,
    BookingStatus.checkedIn,
    BookingStatus.checkedOut,
    BookingStatus.noShow,
  ];

  static const _emptyMessages = [
    'Không có đặt phòng đã xác nhận',
    'Không có khách đang ở',
    'Không có lịch sử trả phòng',
    'Không có trường hợp vắng mặt',
  ];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    _bookingsFuture = _bookingRepository.getBookingsByCustomerId(
      widget.customer.userId,
    );
  }

  String _formatDateCompact(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToBooking(BookingScheduleItem booking) async {
    String? route;
    switch (booking.status) {
      case BookingStatus.confirmed:
        route = '/booking-details/${booking.id}';
        break;
      case BookingStatus.checkedIn:
        route = '/stay-management/${booking.id}';
        break;
      case BookingStatus.checkedOut:
        route = '/bill-details/${booking.id}';
        break;
      case BookingStatus.noShow:
        route = '/booking-details/${booking.id}';
        break;
    }
    final result = await Navigator.pushNamed(context, route);
    if (result == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Thao tác thành công!')));
      setState(() => _loadBookings());
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Đặt phòng của ${customer.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Customer info ───────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundImage:
                    (customer.avatar != null && customer.avatar!.isNotEmpty)
                    ? NetworkImage(customer.avatar!)
                    : null,
                child: (customer.avatar == null || customer.avatar!.isEmpty)
                    ? const Icon(Icons.person, size: 36)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          customer.phone,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => setState(() => _loadBookings()),
              ),
            ],
          ),

          const Divider(height: 32),

          // ── Section header ──────────────────────────────────────────
          const Text(
            'Danh sách đặt phòng',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // ── 4-status ToggleButtons ──────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ToggleButtons(
              isSelected: List.generate(
                _tabStatuses.length,
                (i) => i == _selectedTabIndex,
              ),
              onPressed: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              borderRadius: BorderRadius.circular(8),
              constraints: const BoxConstraints(minHeight: 36, minWidth: 90),
              children: _tabLabels
                  .map(
                    (label) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(label, style: const TextStyle(fontSize: 13)),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 16),

          // ── Filtered booking list ───────────────────────────────────
          FutureBuilder<List<BookingScheduleItem>>(
            future: _bookingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Lỗi tải đặt phòng: ${snapshot.error}'),
                );
              }

              final bookings = snapshot.data ?? [];
              final activeStatus = _tabStatuses[_selectedTabIndex];
              final filtered = bookings
                  .where((b) => b.status == activeStatus)
                  .toList();

              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _emptyMessages[_selectedTabIndex],
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              return Column(
                children: filtered
                    .map(
                      (b) => _BookingItem(
                        booking: b,
                        onTap: () => _navigateToBooking(b),
                        formatDate: _formatDateCompact,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Booking list item ─────────────────────────────────────────────────────────

class _BookingItem extends StatelessWidget {
  final BookingScheduleItem booking;
  final VoidCallback onTap;
  final String Function(DateTime) formatDate;

  const _BookingItem({
    required this.booking,
    required this.onTap,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final roomLabel = booking.roomName != null
        ? 'Phòng ${booking.roomName}'
        : 'Phòng #${booking.roomId}';
    final dateRange =
        '${formatDate(booking.checkInDateTime)} – ${formatDate(booking.checkoutDateTime)}';

    return Card(
      clipBehavior: Clip.hardEdge,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          roomLabel,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  dateRange,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}
