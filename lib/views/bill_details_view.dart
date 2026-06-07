import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/booking_details.dart';
import 'package:hms_app/models/dtos/room_details.dart';
import 'package:hms_app/models/fee.dart';
import 'package:hms_app/repositories/booking_repository.dart';
import 'package:hms_app/repositories/fee_repository.dart';
import 'package:hms_app/repositories/room_repository.dart';
import 'package:hms_app/utils/format_vnd.dart';
import 'package:hms_app/widgets/time_row.dart';

class BillDetailsView extends StatefulWidget {
  final int bookingId;
  const BillDetailsView({super.key, required this.bookingId});

  @override
  State<BillDetailsView> createState() => _BillDetailsViewState();
}

class _BillDetailsData {
  final BookingDetails booking;
  final RoomDetails room;
  final List<Fee> fees;

  _BillDetailsData({
    required this.booking,
    required this.room,
    required this.fees,
  });
}

class _BillDetailsViewState extends State<BillDetailsView> {
  final _bookingRepository = BookingRepository();
  final _roomRepository = RoomRepository();
  final _feeRepository = FeeRepository();

  late final Future<_BillDetailsData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<_BillDetailsData> _fetchData() async {
    final booking = await _bookingRepository.getBookingDetailsWithServices(
      widget.bookingId,
    );
    final room = await _roomRepository.getRoomDetails(booking.roomId);
    final fees = await _feeRepository.getFeesByBookingId(widget.bookingId);
    return _BillDetailsData(booking: booking, room: room, fees: fees);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết hoá đơn')),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed('/room-map'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Về trang chủ'),
        ),
      ),
      body: FutureBuilder<_BillDetailsData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Không tìm thấy dữ liệu'));
          }

          final data = snapshot.data!;
          final booking = data.booking;
          final room = data.room;
          final fees = data.fees;
          final colorScheme = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;

          final serviceFees = fees
              .where((f) => f.type == FeeType.service)
              .toList();
          final roomFees = fees
              .where((f) => f.type == FeeType.roomFee)
              .toList();
          final extraFees = fees
              .where((f) => f.type == FeeType.extraFee)
              .toList();
          final totalAmount = fees.fold(0, (sum, f) => sum + f.totalPrice);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Room and guest information ─────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (room.imageUrl != null)
                    Image.network(
                      room.imageUrl!,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      width: 110,
                      height: 110,
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phòng ${room.roomName} - ${room.typeName}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Khách: ${booking.customerName}',
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurface,
                              ),
                              children: [
                                const TextSpan(text: 'Trạng thái: '),
                                TextSpan(
                                  text: 'Đã trả phòng',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(height: 32),

              // ── Stay Duration Card ─────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thời gian lưu trú',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      buildTimeRow(
                        context,
                        icon: Icons.login_outlined,
                        label: 'Check-in (chuẩn)',
                        dateTime: booking.checkInDateTime,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: SizedBox(
                          height: 16,
                          child: VerticalDivider(width: 1, thickness: 1),
                        ),
                      ),
                      buildTimeRow(
                        context,
                        icon: Icons.login,
                        label: 'Check-in (thực tế)',
                        dateTime:
                            booking.actualCheckInDateTime ??
                            booking.checkInDateTime,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: SizedBox(
                          height: 16,
                          child: VerticalDivider(width: 1, thickness: 1),
                        ),
                      ),
                      buildTimeRow(
                        context,
                        icon: Icons.logout_outlined,
                        label: 'Check-out (dự kiến)',
                        dateTime: booking.checkoutDateTime,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: SizedBox(
                          height: 16,
                          child: VerticalDivider(width: 1, thickness: 1),
                        ),
                      ),
                      buildTimeRow(
                        context,
                        icon: Icons.logout,
                        label: 'Check-out (thực tế)',
                        dateTime:
                            booking.actualCheckOutDateTime ?? DateTime.now(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 32),

              // ── Billing Summary ────────────────────────────────────────
              Text(
                'Chi tiết thanh toán',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),

              // ── Services ──────────────────────────────────────────────
              Text(
                'Dịch vụ',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              _FeeSection(
                fees: serviceFees,
                emptyLabel: 'Không có dịch vụ nào',
              ),

              const SizedBox(height: 12),

              // ── Room Fees ─────────────────────────────────────────────
              Text(
                'Tiền phòng',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              _FeeSection(fees: roomFees, emptyLabel: 'Không có tiền phòng'),

              const SizedBox(height: 12),

              // ── Extra Fees ────────────────────────────────────────────
              Text(
                'Phí phát sinh',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              _FeeSection(fees: extraFees, emptyLabel: 'Chưa có phí phát sinh'),

              const SizedBox(height: 24),

              // ── Grand Total ───────────────────────────────────────────
              Card(
                color: colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng cộng',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        '${formatVND(totalAmount)} đ',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

class _FeeSection extends StatelessWidget {
  final List<Fee> fees;
  final String emptyLabel;

  const _FeeSection({required this.fees, required this.emptyLabel});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: fees.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: Text(emptyLabel)),
            )
          : Column(
              children: [
                for (int i = 0; i < fees.length; i++) ...[
                  ListTile(
                    title: Text(
                      fees[i].title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: fees[i].subtitle != null
                        ? Text(fees[i].subtitle!)
                        : null,
                    trailing: Text(
                      '${formatVND(fees[i].totalPrice)} đ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (i < fees.length - 1) const Divider(height: 1),
                ],
              ],
            ),
    );
  }
}
