import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/booking_schedule_item.dart';
import 'package:hms_app/models/enums/booking_status.dart';

class BookingCard extends StatelessWidget {
  final BookingScheduleItem booking;

  const BookingCard({super.key, required this.booking});

  (String label, Color color) _statusDisplay(
    BookingStatus status,
    ColorScheme cs,
  ) {
    return switch (status) {
      BookingStatus.confirmed => ('Đã đặt cọc', cs.primary),
      BookingStatus.checkedIn => ('Đang ở', Colors.green),
      BookingStatus.checkedOut => ('Đã trả phòng', cs.outline),
      BookingStatus.noShow => ('Vắng mặt', Colors.red),
    };
  }

  void _navigateToBookingDetails(BuildContext context) {
    if (booking.status == BookingStatus.confirmed) {
      Navigator.pushNamed(context, '/booking-details/${booking.id}');
    } else if (booking.status == BookingStatus.checkedIn) {
      Navigator.pushNamed(context, '/stay-management/${booking.id}');
    } else if (booking.status == BookingStatus.checkedOut) {
      Navigator.pushNamed(context, '/bill-details/${booking.id}');
    } else if (booking.status == BookingStatus.noShow) {
      Navigator.pushNamed(context, '/bill-details/${booking.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkIn = booking.checkInDateTime;
    final checkOut = booking.checkoutDateTime;
    final dateRange =
        '${checkIn.day}/${checkIn.month} – ${checkOut.day}/${checkOut.month}/${checkOut.year}';

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final (statusLabel, statusColor) = _statusDisplay(
      booking.status,
      colorScheme,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToBookingDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar — mirrors BookingDetailsScreen
              CircleAvatar(
                radius: 32,
                backgroundImage: booking.customerAvatar != null
                    ? NetworkImage(booking.customerAvatar!)
                    : null,
                child: booking.customerAvatar == null
                    ? const Icon(Icons.person, size: 32)
                    : null,
              ),
              const SizedBox(width: 16),
              // Name + phone + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customerName,
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
                          booking.customerPhone,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateRange,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status chip — mirrors BookingDetailsScreen
              Chip(
                label: Text(
                  statusLabel,
                  style: textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                side: BorderSide(color: statusColor.withValues(alpha: 0.4)),
                backgroundColor: statusColor.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
