import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/booking_schedule_item.dart';
import 'package:hms_app/models/enums/booking_status.dart';
import 'package:hms_app/repositories/booking_repository.dart';
import 'package:hms_app/widgets/date_time_picker.dart';

class BookingDetailsScreen extends StatefulWidget {
  final int bookingId;
  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  late Future<BookingScheduleItem> _detailsFuture;
  final _bookingRepository = BookingRepository();

  DateTime? _checkIn;
  DateTime? _checkOut;
  bool _isDeleting = false;
  bool _isCheckingIn = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _bookingRepository.getBookingDetails(widget.bookingId);
  }

  Future<void> _pickDateTime({required bool isCheckIn}) async {
    final initial = isCheckIn ? _checkIn : _checkOut;
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final hour = isCheckIn ? 14 : 12;
    final result = DateTime(date.year, date.month, date.day, hour, 0);

    setState(() {
      if (isCheckIn) {
        _checkIn = result;
      } else {
        _checkOut = result;
      }
    });
  }

  Future<void> _handleCheckIn(int roomId) async {
    setState(() {
      _isCheckingIn = true;
    });
    try {
      await _bookingRepository.checkIn(widget.bookingId, roomId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Check-in thành công!')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi check-in: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingIn = false;
        });
      }
    }
  }

  Future<void> _handleUpdate(int roomId) async {
    if (_checkIn == null || _checkOut == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await _bookingRepository.updateBooking(
        roomId: roomId,
        bookingId: widget.bookingId,
        checkInDateTime: _checkIn!,
        checkOutDateTime: _checkOut!,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi cập nhật: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _confirmAndDeleteBooking() async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc muốn xóa đặt phòng này không? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _bookingRepository.deleteBooking(widget.bookingId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi xóa: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Chưa chọn';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}  $h:$min';
  }

  (String label, Color color) _statusDisplay(
    BookingStatus status,
    ColorScheme cs,
  ) {
    return switch (status) {
      BookingStatus.confirmed => ('Đã xác nhận', cs.primary),
      BookingStatus.checkedIn => ('Đang ở', Colors.green),
      BookingStatus.checkedOut => ('Đã trả phòng', cs.outline),
      BookingStatus.noShow => ('Không đến', Colors.red),
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BookingScheduleItem>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết đặt phòng')),
            body: Center(child: Text('Lỗi: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết đặt phòng')),
            body: const Center(child: Text('Không tìm thấy')),
          );
        }

        final booking = snapshot.data!;
        _checkIn ??= booking.checkInDateTime.toLocal();
        _checkOut ??= booking.checkoutDateTime.toLocal();

        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        final (statusLabel, statusColor) = _statusDisplay(
          booking.status,
          colorScheme,
        );

        return Scaffold(
          appBar: AppBar(title: const Text('Chi tiết đặt phòng')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Customer card ──────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Date/time pickers ──────────────────────────────────
              Text(
                'Thời gian đặt phòng',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              DateTimePicker(
                label: 'Nhận phòng',
                icon: Icons.login,
                value: _formatDateTime(_checkIn),
                onTap: () => _pickDateTime(isCheckIn: true),
              ),
              const SizedBox(height: 8),
              DateTimePicker(
                label: 'Trả phòng',
                icon: Icons.logout,
                value: _formatDateTime(_checkOut),
                onTap: () => _pickDateTime(isCheckIn: false),
              ),

              const SizedBox(height: 16),

              // ── Status chip ────────────────────────────────────────
              Row(
                children: [
                  Text(
                    'Trạng thái: ',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
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
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Check in – full width
                if (booking.status == BookingStatus.confirmed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isCheckingIn || _isDeleting || _isUpdating
                            ? null
                            : () => _handleCheckIn(booking.roomId),
                        icon: _isCheckingIn
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.login),
                        label: Text(
                          _isCheckingIn ? 'Đang check in...' : 'Check in',
                        ),
                      ),
                    ),
                  ),
                // Row 2: Xóa | Cập nhật
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isDeleting || _isCheckingIn || _isUpdating
                            ? null
                            : _confirmAndDeleteBooking,
                        icon: _isDeleting
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.error,
                                ),
                              )
                            : Icon(
                                Icons.delete_outline,
                                color: colorScheme.error,
                              ),
                        label: Text(
                          _isDeleting ? 'Đang xóa...' : 'Xóa',
                          style: TextStyle(color: colorScheme.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colorScheme.error),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isCheckingIn || _isDeleting || _isUpdating
                            ? null
                            : () => _handleUpdate(booking.roomId),
                        icon: _isUpdating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(_isUpdating ? 'Đang lưu...' : 'Cập nhật'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
