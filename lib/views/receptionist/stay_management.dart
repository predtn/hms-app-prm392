import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/booking_details.dart';
import 'package:hms_app/models/dtos/service_usage.dart';
import 'package:hms_app/services/booking_service.dart';
import 'package:hms_app/services/service_catalog_service.dart';
import 'package:hms_app/utils/app_dialogs.dart';
import 'package:hms_app/utils/format_vnd.dart';
import 'package:hms_app/views/receptionist/widgets/date_time_picker.dart';
import 'package:hms_app/views/receptionist/widgets/service_card.dart';
import 'package:hms_app/views/receptionist/widgets/time_row.dart';

class StayManagement extends StatefulWidget {
  final int bookingId;

  const StayManagement({super.key, required this.bookingId});

  @override
  State<StayManagement> createState() => _StayManagementState();
}

class _StayManagementState extends State<StayManagement> {
  late Future<BookingDetails> _detailsFuture;
  final _bookingService = BookingService();
  final _serviceCatalogService = ServiceCatalogService();
  DateTime? _checkoutDateTime;
  List<ServiceUsage>? _currentUsages;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _bookingService.getBookingDetailsWithServices(
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
      await _serviceCatalogService.updateServiceUsage(
        widget.bookingId,
        _currentUsages!,
      );

      await _bookingService.updateBooking(
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
        await showErrorDialog(context, 'Lỗi: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

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
        final textTheme = Theme.of(context).textTheme;

        return Scaffold(
          backgroundColor: color.surface,
          appBar: AppBar(
            title: const Text('Quản lý lưu trú'),
            centerTitle: true,
            backgroundColor: color.surface,
            iconTheme: IconThemeData(color: color.onSurface),
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Customer Info Card (using the requested grey-bordered design)
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
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: color.primary.withAlpha(20),
                        backgroundImage:
                            details.customerAvatar != null &&
                                details.customerAvatar!.isNotEmpty
                            ? NetworkImage(details.customerAvatar!)
                            : null,
                        child:
                            details.customerAvatar == null ||
                                details.customerAvatar!.isEmpty
                            ? Icon(Icons.person, size: 28, color: color.primary)
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
                                color: color.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  size: 14,
                                  color: color.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  details.customerPhone,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.onSurfaceVariant,
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

              // ── Stay Duration Card ─────────────────────────────────────
              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: color.outlineVariant.withAlpha(100),
                    width: 1,
                  ),
                ),
                color: color.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thời gian lưu trú',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color.onSurface,
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
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: SizedBox(
                          height: 20,
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

              const SizedBox(height: 16),

              DateTimePicker(
                label: 'Chỉnh sửa thời gian ở',
                icon: Icons.schedule_outlined,
                value: _formatDt(_checkoutDateTime!),
                onTap: _pickCheckout,
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 20,
                    color: color.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Phí dịch vụ',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_currentUsages!.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: color.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.outlineVariant.withAlpha(60),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Không sử dụng dịch vụ nào',
                      style: TextStyle(
                        color: color.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                ..._currentUsages!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final usage = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ServiceCard(
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
                    ),
                  );
                }),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.surface,
                border: Border(
                  top: BorderSide(
                    color: color.outlineVariant.withAlpha(60),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: color.primary),
                      ),
                      onPressed: _isSaving ? null : () => _saveChanges(details),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Lưu thay đổi',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/check-out/${details.id}',
                        );
                      },
                      child: const Text(
                        'Check out',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
