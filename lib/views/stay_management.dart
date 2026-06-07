import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/booking_details.dart';
import 'package:hms_app/models/dtos/service_usage.dart';
import 'package:hms_app/repositories/booking_repository.dart';
import 'package:hms_app/repositories/service_repository.dart';
import 'package:hms_app/utils/format_vnd.dart';
import 'package:hms_app/widgets/date_time_picker.dart';
import 'package:hms_app/widgets/service_card.dart';
import 'package:hms_app/widgets/time_row.dart';

class StayManagement extends StatefulWidget {
  final int bookingId;

  const StayManagement({super.key, required this.bookingId});

  @override
  State<StayManagement> createState() => _StayManagementState();
}

class _StayManagementState extends State<StayManagement> {
  late Future<BookingDetails> _detailsFuture;
  final _bookingRepository = BookingRepository();
  final _serviceRepository = ServiceRepository();
  DateTime? _checkoutDateTime;
  List<ServiceUsage>? _currentUsages;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _bookingRepository.getBookingDetailsWithServices(
      widget.bookingId,
    );
  }

  Future<void> _pickCheckout() async {
    final current = _checkoutDateTime!;
    final now = DateTime.now();
    final initialDate = current.isBefore(now) ? now : current;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    setState(() {
      _checkoutDateTime = DateTime(date.year, date.month, date.day, 12, 0);
    });
  }

  String _formatDt(DateTime dt) {
    final l = dt.toLocal();
    final d = l.day.toString().padLeft(2, '0');
    final m = l.month.toString().padLeft(2, '0');
    final h = l.hour.toString().padLeft(2, '0');
    final min = l.minute.toString().padLeft(2, '0');
    return '$d/$m/${l.year} $h:$min';
  }

  Future<void> _saveChanges(BookingDetails details) async {
    setState(() => _isSaving = true);
    try {
      await _serviceRepository.updateServiceUsage(
        widget.bookingId,
        _currentUsages!,
      );

      await _bookingRepository.updateBooking(
        roomId: details.roomId,
        bookingId: widget.bookingId,
        checkInDateTime:
            details.actualCheckInDateTime ?? details.checkInDateTime,
        checkOutDateTime: _checkoutDateTime!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lưu thay đổi thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BookingDetails>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Quản lý lưu trú')),
            body: Center(child: Text('Lỗi: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Quản lý lưu trú')),
            body: const Center(child: Text('Không tìm thấy thông tin')),
          );
        }

        final details = snapshot.data!;
        _checkoutDateTime ??=
            details.actualCheckOutDateTime ?? details.checkoutDateTime;
        _currentUsages ??= List.from(details.usedServices);
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Scaffold(
          appBar: AppBar(title: const Text('Quản lý lưu trú')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Customer Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: details.customerAvatar != null
                            ? NetworkImage(details.customerAvatar!)
                            : null,
                        child: details.customerAvatar == null
                            ? const Icon(Icons.person, size: 32)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              details.customerName,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ...[
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
                                  details.customerPhone!,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

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
                        label: 'Check-in',
                        dateTime:
                            details.actualCheckInDateTime ??
                            details.checkInDateTime,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        child: SizedBox(
                          height: 24,
                          child: VerticalDivider(width: 1, thickness: 1),
                        ),
                      ),
                      buildTimeRow(
                        context,
                        icon: Icons.logout_outlined,
                        label: 'Check-out (dự kiến)',
                        dateTime:
                            details.actualCheckOutDateTime ??
                            details.checkoutDateTime,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DateTimePicker(
                label: 'Chỉnh sửa thời gian ở',
                icon: Icons.schedule_outlined,
                value: _formatDt(_checkoutDateTime!),
                onTap: _pickCheckout,
              ),
              const SizedBox(height: 12),
              Text(
                'Phí dịch vụ',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ..._currentUsages!.asMap().entries.map((entry) {
                final index = entry.key;
                final usage = entry.value;
                return ServiceCard(
                  imageUrl: usage.service.imageUrl ?? '',
                  title: usage.service.name,
                  subtitle:
                      '${formatVND(usage.service.pricePerUnit)} VND / ${usage.service.unit}',
                  unit: usage.service.unit,
                  initialQuantity: usage.quantity,
                  onChanged: (newQty) {
                    _currentUsages![index] = ServiceUsage(
                      service: usage.service,
                      quantity: newQty,
                    );
                  },
                );
              }),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => _saveChanges(details),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Lưu thay đổi'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/check-out/${details.id}');
                    },
                    child: const Text('Check out'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
