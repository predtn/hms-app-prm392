import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/billing_item.dart';
import 'package:hms_app/models/dtos/booking_details.dart';
import 'package:hms_app/models/dtos/room_details.dart';
import 'package:hms_app/models/fee.dart';
import 'package:hms_app/models/dtos/hotel_pricing_config.dart';
import 'package:hms_app/providers/pricing_config_provider.dart';
import 'package:hms_app/providers/user_provider.dart';
import 'package:hms_app/services/booking_service.dart';
import 'package:hms_app/services/room_service.dart';
import 'package:hms_app/utils/app_dialogs.dart';
import 'package:hms_app/utils/calculate_room_price.dart';
import 'package:hms_app/utils/format_vnd.dart';
import 'package:hms_app/views/receptionist/widgets/time_row.dart';
import 'package:provider/provider.dart';
import 'package:hms_app/models/enums/user_role.dart';

class CheckOutView extends StatefulWidget {
  final int bookingId;
  const CheckOutView({super.key, required this.bookingId});

  @override
  State<CheckOutView> createState() => _CheckOutViewState();
}

class _CheckoutData {
  final BookingDetails booking;
  final RoomDetails room;

  _CheckoutData({required this.booking, required this.room});
}

class _CheckOutViewState extends State<CheckOutView> {
  final _bookingService = BookingService();
  final _roomService = RoomService();
  late Future<_CheckoutData> _dataFuture;

  List<BillingItem> _billingItems = [];
  final List<BillingItem> _extraItems = [];
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  void _initBillingItems(BookingDetails booking) {
    _billingItems = booking.usedServices
        .where((u) => u.quantity > 0)
        .map(
          (u) => BillingItem(
            title: u.service.name,
            subtitle:
                '${formatVND(u.service.pricePerUnit)} đ x ${u.quantity} ${u.service.unit}',
            price: u.quantity * u.service.pricePerUnit,
            type: FeeType.service,
          ),
        )
        .toList();
  }

  List<BillingItem> _getRoomFeeItems({
    required BookingDetails booking,
    required RoomDetails room,
    required HotelPricingConfig config,
  }) {
    final breakdown = calculateHotelPrice(
      checkInDateTime: booking.checkInDateTime,
      checkOutDateTime: booking.checkoutDateTime,
      actualCheckInDateTime: booking.actualCheckInDateTime,
      actualCheckOutDateTime: booking.actualCheckOutDateTime ?? DateTime.now(),
      pricePerNight: room.pricePerNight,
      config: config,
    );

    return [
      BillingItem(
        title: 'Tiền phòng cơ bản',
        subtitle: '${formatVND(room.pricePerNight)} đ / đêm',
        price: breakdown.coreRoomFee,
        type: FeeType.roomFee,
      ),
      if (breakdown.extraFeeForCheckIn > 0)
        BillingItem(
          title: 'Phụ thu nhận phòng sớm',
          subtitle: 'Check-in trước 14:00',
          price: breakdown.extraFeeForCheckIn,
          type: FeeType.roomFee,
        ),
      if (breakdown.extraFeeForCheckOut > 0)
        BillingItem(
          title: 'Phụ thu trả phòng muộn',
          subtitle: 'Check-out sau 12:00',
          price: breakdown.extraFeeForCheckOut,
          type: FeeType.roomFee,
        ),
    ];
  }

  Future<_CheckoutData> _fetchData() async {
    final booking = await _bookingService.getBookingDetailsWithServices(
      widget.bookingId,
    );
    final room = await _roomService.getRoomDetails(booking.roomId);
    if (mounted) {
      setState(() {
        _initBillingItems(booking);
      });
    }
    return _CheckoutData(booking: booking, room: room);
  }

  Future<void> _goToPayment(List<BillingItem> roomFeeItems) async {
    final totalAmount = [
      ..._billingItems,
      ...roomFeeItems,
      ..._extraItems,
    ].fold(0, (sum, item) => sum + item.price);

    final confirmed = await Navigator.pushNamed<bool>(
      context,
      '/payment/$totalAmount',
    );
    if (confirmed != true) return;

    setState(() => _isCheckingOut = true);
    try {
      final allItems = [..._billingItems, ...roomFeeItems, ..._extraItems];
      await _bookingService.completeCheckout(
        bookingId: widget.bookingId,
        billingItems: allItems,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, 'Lỗi khi thanh toán: $e');
      }
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  Future<void> _showAddExtraItemDialog() async {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Thêm phí phát sinh',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Tên khoản phí *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập tên'
                    : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: subtitleController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (tuỳ chọn)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Số tiền (đ) *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Vui lòng nhập số tiền';
                  }
                  final parsed = int.tryParse(v.trim().replaceAll(',', ''));
                  if (parsed == null || parsed <= 0) {
                    return 'Số tiền không hợp lệ';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final price = int.parse(
                priceController.text.trim().replaceAll(',', ''),
              );
              setState(() {
                _extraItems.add(
                  BillingItem(
                    title: titleController.text.trim(),
                    subtitle: subtitleController.text.trim().isEmpty
                        ? 'Phí phát sinh'
                        : subtitleController.text.trim(),
                    price: price,
                    type: FeeType.extraFee,
                  ),
                );
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pricingConfig = context.watch<PricingConfigProvider>().config;
    final canManageHotelConfig =
        context.watch<UserProvider>().userProfile?.role.canManageHotelConfig ??
        false;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: const Text('Check Out'),
        centerTitle: true,
        backgroundColor: color.surface,
        iconTheme: IconThemeData(color: color.onSurface),
        elevation: 0,
      ),
      body: FutureBuilder<_CheckoutData>(
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
          final room = data.room;
          final booking = data.booking;
          final textTheme = Theme.of(context).textTheme;

          final roomFeeItems = _getRoomFeeItems(
            booking: booking,
            room: room,
            config: pricingConfig,
          );

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // ── Room and guest information (custom card matching the user's preferred design) ──
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image section with nice borders
                      if (room.imageUrl != null && room.imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            room.imageUrl!,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 90,
                                  height: 90,
                                  color: color.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.hotel_outlined,
                                    color: color.onSurfaceVariant,
                                  ),
                                ),
                          ),
                        )
                      else
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: color.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.hotel_outlined,
                            color: color.onSurfaceVariant,
                          ),
                        ),

                      const SizedBox(width: 16),

                      // Content section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phòng ${room.roomName}',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              room.typeName,
                              style: textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Khách: ${booking.customerName}',
                              style: textTheme.bodyMedium?.copyWith(
                                color: color.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                          color: color.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: color.primary.withAlpha(50),
                          ),
                        ),
                        child: Text(
                          'Đang ở',
                          style: TextStyle(
                            color: color.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
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
                    color: color.outlineVariant.withAlpha(120),
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
                        label: 'Check-in (chuẩn)',
                        dateTime: booking.checkInDateTime,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: SizedBox(
                          height: 12,
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
                          height: 12,
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
                          height: 12,
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

              const SizedBox(height: 24),

              // ── Billing Summary ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.payment_outlined,
                        size: 20,
                        color: color.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Chi tiết thanh toán',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color.onSurface,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    onPressed: _showAddExtraItemDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'Thêm phí',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Services sub-section ─────────────────────────────────────
              Text(
                'Dịch vụ đã dùng',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Card(
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
                child: _billingItems.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        child: Center(
                          child: Text(
                            'Không sử dụng dịch vụ nào',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (int i = 0; i < _billingItems.length; i++) ...[
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              title: Text(
                                _billingItems[i].title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                _billingItems[i].subtitle,
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Text(
                                '${formatVND(_billingItems[i].price)} đ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: color.primary,
                                ),
                              ),
                            ),
                            if (i < _billingItems.length - 1)
                              Divider(
                                height: 1,
                                color: color.outlineVariant.withAlpha(80),
                              ),
                          ],
                        ],
                      ),
              ),

              const SizedBox(height: 20),

              // ── Room Fee sub-section ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Tiền phòng',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  if (canManageHotelConfig)
                    TextButton.icon(
                      icon: const Icon(Icons.settings_outlined, size: 16),
                      label: const Text(
                        'Cấu hình phụ thu',
                        style: TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/penalty-fee-config');
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
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
                child: Column(
                  children: [
                    for (int i = 0; i < roomFeeItems.length; i++) ...[
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        title: Text(
                          roomFeeItems[i].title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          roomFeeItems[i].subtitle,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          '${formatVND(roomFeeItems[i].price)} đ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: color.primary,
                          ),
                        ),
                      ),
                      if (i < roomFeeItems.length - 1)
                        Divider(
                          height: 1,
                          color: color.outlineVariant.withAlpha(80),
                        ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Extra Fee sub-section ─────────────────────────────────────
              Text(
                'Phí phát sinh khác',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Card(
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
                child: _extraItems.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        child: Center(
                          child: Text(
                            'Chưa có khoản phí phát sinh nào',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (int i = 0; i < _extraItems.length; i++) ...[
                            ListTile(
                              contentPadding: const EdgeInsets.only(
                                left: 16,
                                right: 8,
                                top: 4,
                                bottom: 4,
                              ),
                              title: Text(
                                _extraItems[i].title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                _extraItems[i].subtitle,
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${formatVND(_extraItems[i].price)} đ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: color.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                    ),
                                    color: Colors.redAccent,
                                    tooltip: 'Xoá',
                                    onPressed: () {
                                      setState(() => _extraItems.removeAt(i));
                                    },
                                  ),
                                ],
                              ),
                            ),
                            if (i < _extraItems.length - 1)
                              Divider(
                                height: 1,
                                color: color.outlineVariant.withAlpha(80),
                              ),
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<_CheckoutData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();

          final data = snapshot.data!;
          final roomFeeItems = _getRoomFeeItems(
            booking: data.booking,
            room: data.room,
            config: pricingConfig,
          );
          final totalAmount = [
            ..._billingItems,
            ...roomFeeItems,
            ..._extraItems,
          ].fold(0, (sum, item) => sum + item.price);

          return Container(
            decoration: BoxDecoration(
              color: color.surfaceContainerLow,
              border: Border(
                top: BorderSide(
                  color: color.outlineVariant.withAlpha(120),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng cộng thanh toán',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${formatVND(totalAmount)} đ',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: color.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _isCheckingOut
                        ? null
                        : () => _goToPayment(roomFeeItems),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isCheckingOut
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Xác nhận Thanh toán & Check out',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
