import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/billing_item.dart';
import 'package:hms_app/models/dtos/booking_details.dart';
import 'package:hms_app/models/dtos/room_details.dart';
import 'package:hms_app/models/fee.dart';
import 'package:hms_app/models/dtos/hotel_pricing_config.dart';
import 'package:hms_app/providers/pricing_config_provider.dart';
import 'package:hms_app/providers/user_provider.dart';
import 'package:hms_app/repositories/booking_repository.dart';
import 'package:hms_app/repositories/fee_repository.dart';
import 'package:hms_app/repositories/room_repository.dart';
import 'package:hms_app/utils/app_dialogs.dart';
import 'package:hms_app/utils/calculate_room_price.dart';
import 'package:hms_app/utils/format_vnd.dart';
import 'package:hms_app/widgets/time_row.dart';
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
  final _bookingRepository = BookingRepository();
  final _roomRepository = RoomRepository();
  final _feeRepository = FeeRepository();
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
    final booking = await _bookingRepository.getBookingDetailsWithServices(
      widget.bookingId,
    );
    final room = await _roomRepository.getRoomDetails(booking.roomId);
    // Initialise billing items from fetched booking data
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
      await _feeRepository.addFees(allItems, widget.bookingId);
      await _bookingRepository.checkOut(widget.bookingId);

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
        title: const Text('Thêm phí phát sinh'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Tên khoản phí *',
                  border: OutlineInputBorder(),
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
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Số tiền (đ) *',
                  border: OutlineInputBorder(),
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
    // Watch the pricing config to rebuild when it changes
    final pricingConfig = context.watch<PricingConfigProvider>().config;
    final canManageHotelConfig =
        context.watch<UserProvider>().userProfile?.role.canManageHotelConfig ??
        false;

    return Scaffold(
      appBar: AppBar(title: const Text('Check Out')),
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
          final colorScheme = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;

          final roomFeeItems = _getRoomFeeItems(
            booking: booking,
            room: room,
            config: pricingConfig,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Room and guest information ────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image section
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

                  // Content section
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
                                  text: 'Đang ở',
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
              // End room details section
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
                      // Row 1: Scheduled check-in
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
                      // Row 2: Actual check-in
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
                      // Row 3: Scheduled check-out
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
                      // Row 4: Actual check-out (DateTime.now() as placeholder when null)
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

              // ── Billing Summary ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Chi tiết thanh toán',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showAddExtraItemDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Thêm phí'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Services sub-section ─────────────────────────────────────
              Text(
                'Dịch vụ',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Card(
                child: _billingItems.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('Không có dịch vụ nào')),
                      )
                    : Column(
                        children: [
                          for (int i = 0; i < _billingItems.length; i++) ...[
                            ListTile(
                              title: Text(
                                _billingItems[i].title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(_billingItems[i].subtitle),
                              trailing: Text(
                                '${formatVND(_billingItems[i].price)} đ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (i < _billingItems.length - 1)
                              const Divider(height: 1),
                          ],
                        ],
                      ),
              ),

              const SizedBox(height: 12),

              // ── Room Fee sub-section ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Tiền phòng',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (canManageHotelConfig)
                    TextButton.icon(
                      icon: const Icon(Icons.money_outlined, size: 18),
                      label: const Text('Cài đặt phụ phí'),
                      onPressed: () {
                        Navigator.pushNamed(context, '/penalty-fee-config');
                      },
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Card(
                child: Column(
                  children: [
                    for (int i = 0; i < roomFeeItems.length; i++) ...[
                      ListTile(
                        title: Text(
                          roomFeeItems[i].title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(roomFeeItems[i].subtitle),
                        trailing: Text(
                          '${formatVND(roomFeeItems[i].price)} đ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (i < roomFeeItems.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Extra Fee sub-section ─────────────────────────────────────
              Text(
                'Phí phát sinh',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Card(
                child: _extraItems.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('Chưa có phí phát sinh')),
                      )
                    : Column(
                        children: [
                          for (int i = 0; i < _extraItems.length; i++) ...[
                            ListTile(
                              title: Text(
                                _extraItems[i].title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(_extraItems[i].subtitle),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${formatVND(_extraItems[i].price)} đ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                    ),
                                    color: Colors.red,
                                    tooltip: 'Xoá',
                                    onPressed: () {
                                      setState(() => _extraItems.removeAt(i));
                                    },
                                  ),
                                ],
                              ),
                            ),
                            if (i < _extraItems.length - 1)
                              const Divider(height: 1),
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

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng cộng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${formatVND(totalAmount)} đ',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _isCheckingOut ? null : () => _goToPayment(roomFeeItems),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
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
                      : const Text('Thanh toán'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
