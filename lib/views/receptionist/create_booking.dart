import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hms_app/models/dtos/customer_short_detail.dart';
import 'package:hms_app/models/dtos/room_details.dart';
import 'package:hms_app/providers/booking_draft_provider.dart';
import 'package:hms_app/providers/booking_provider.dart';
import 'package:hms_app/providers/room_provider.dart';
import 'package:hms_app/providers/user_provider.dart';
import 'package:hms_app/utils/app_dialogs.dart';
import 'package:hms_app/utils/date_diff.dart';
import 'package:hms_app/views/receptionist/widgets/date_time_picker.dart';
import 'package:hms_app/views/receptionist/widgets/room_detail_card.dart';

class CreateBookingScreen extends StatefulWidget {
  const CreateBookingScreen({super.key, required this.roomId});

  final int roomId;

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  late Future<RoomDetails> _roomDetailsFuture;
  String get _draftKey => BookingDraftProvider.singleRoomKey(widget.roomId);
  BookingDraftProvider get _bookingDraftProvider =>
      context.read<BookingDraftProvider>();
  RoomProvider get _roomProvider => context.read<RoomProvider>();
  BookingProvider get _bookingProvider => context.read<BookingProvider>();
  UserProvider get _userProvider => context.read<UserProvider>();

  late final TextEditingController _guestNameController;
  late final TextEditingController _phoneController;
  late Future<List<CustomerShortDetail>> _customersFuture;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _bookingDraftProvider.initializeDraft(_draftKey);
    final draft = _bookingDraftProvider.getDraft(_draftKey);
    _guestNameController = TextEditingController(text: draft.guestName);
    _phoneController = TextEditingController(text: draft.phone);
    _guestNameController.addListener(_syncGuestName);
    _phoneController.addListener(_syncPhone);
    _roomDetailsFuture = _roomProvider.getRoomDetails(widget.roomId);
    _customersFuture = _userProvider.getAllCustomers();
  }

  @override
  void dispose() {
    _guestNameController.removeListener(_syncGuestName);
    _phoneController.removeListener(_syncPhone);
    _guestNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _syncGuestName() {
    _bookingDraftProvider.setGuestName(_draftKey, _guestNameController.text);
  }

  void _syncPhone() {
    _bookingDraftProvider.setPhone(_draftKey, _phoneController.text);
  }

  Future<void> _pickDateTime({required bool isCheckIn}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    final hour = isCheckIn ? 14 : 12;

    final result = DateTime(date.year, date.month, date.day, hour, 0);

    if (isCheckIn) {
      _bookingDraftProvider.setCheckIn(_draftKey, result);
    } else {
      _bookingDraftProvider.setCheckOut(_draftKey, result);
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Chưa chọn';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submitBooking() async {
    final String name;
    final String phone;
    final draft = _bookingDraftProvider.getDraft(_draftKey);

    if (draft.isNewCustomer) {
      name = _guestNameController.text.trim();
      phone = _phoneController.text.trim();
    } else {
      name = draft.selectedCustomer?.name ?? '';
      phone = draft.selectedCustomer?.phone ?? '';
    }

    if (name.isEmpty ||
        phone.isEmpty ||
        draft.checkIn == null ||
        draft.checkOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            draft.isNewCustomer
                ? 'Vui lòng điền đầy đủ thông tin'
                : 'Vui lòng chọn khách và điền thời gian',
          ),
        ),
      );
      return;
    }

    if (dateDiffAtLeastOne(draft.checkIn!, draft.checkOut!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ngày trả phòng phải sau ngày nhận phòng ít nhất 1 ngày',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final String userId;
      if (draft.isNewCustomer) {
        userId = await _userProvider.getNewlyCreatedCustomerId(name, phone);
      } else {
        userId = draft.selectedCustomer!.userId;
      }

      await _bookingProvider.createBooking(
        roomId: widget.roomId,
        userId: userId,
        checkInDateTime: draft.checkIn!,
        checkOutDateTime: draft.checkOut!,
        checkInNow: draft.checkInNow,
      );
      if (mounted) {
        _bookingDraftProvider.clearDraft(_draftKey);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, 'Lỗi tạo booking: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        final draft = context.watch<BookingDraftProvider>().getDraft(_draftKey);

        return Scaffold(
          appBar: AppBar(title: Text('Đặt phòng ${room.roomName}')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Section 1: Room details ──────────────────────────
              RoomDetailCard(room: room),

              const SizedBox(height: 20),

              // ── Section 2: Guest information ─────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Thông tin khách',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ToggleButtons(
                    isSelected: [draft.isNewCustomer, !draft.isNewCustomer],
                    onPressed: (index) {
                      _bookingDraftProvider.setIsNewCustomer(
                        _draftKey,
                        index == 0,
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    constraints: const BoxConstraints(
                      minHeight: 36,
                      minWidth: 90,
                    ),
                    children: const [
                      Text('Khách mới', style: TextStyle(fontSize: 13)),
                      Text('Khách cũ', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (draft.isNewCustomer) ...[
                // New customer: fill in name + phone
                TextField(
                  controller: _guestNameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên khách',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                ),
              ] else ...[
                // Old customer: pick from dropdown filtered by phone/name
                FutureBuilder<List<CustomerShortDetail>>(
                  future: _customersFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (snap.hasError) {
                      return Text(
                        'Lỗi tải danh sách khách: ${snap.error}',
                        style: const TextStyle(color: Colors.red),
                      );
                    }
                    final customers = snap.data ?? [];
                    return DropdownMenu<CustomerShortDetail>(
                      hintText: 'Nhập số điện thoại khách hàng...',
                      enableFilter: true,
                      expandedInsets: EdgeInsets.zero,
                      leadingIcon: const Icon(Icons.search),
                      onSelected: (value) => _bookingDraftProvider
                          .setSelectedCustomer(_draftKey, value),
                      dropdownMenuEntries: customers
                          .map(
                            (c) => DropdownMenuEntry<CustomerShortDetail>(
                              value: c,
                              // Searched text matches against this label
                              label: c.phone,
                              leadingIcon: CircleAvatar(
                                radius: 16,
                                backgroundImage: c.avatar?.isNotEmpty == true
                                    ? NetworkImage(c.avatar!)
                                    : null,
                                child: c.avatar?.isNotEmpty == true
                                    ? null
                                    : Text(
                                        c.name.isNotEmpty
                                            ? c.name[0].toUpperCase()
                                            : '?',
                                      ),
                              ),
                              labelWidget: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    c.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    c.phone,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                // Selected Customer Card
                if (draft.selectedCustomer != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    // color: Theme.of(context).colorScheme.primaryContainer,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            draft.selectedCustomer!.avatar?.isNotEmpty == true
                            ? NetworkImage(draft.selectedCustomer!.avatar!)
                            : null,
                        child:
                            draft.selectedCustomer!.avatar?.isNotEmpty == true
                            ? null
                            : Text(
                                draft.selectedCustomer!.name.isNotEmpty
                                    ? draft.selectedCustomer!.name[0]
                                          .toUpperCase()
                                    : '?',
                              ),
                      ),
                      title: Text(
                        draft.selectedCustomer!.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(draft.selectedCustomer!.phone),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Bỏ chọn',
                        onPressed: () => _bookingDraftProvider
                            .setSelectedCustomer(_draftKey, null),
                      ),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 20),

              // ── Section 3: Check-in / Check-out ──────────────────
              const Text(
                'Thời gian đặt phòng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Check-in now toggle
              DateTimePicker(
                label: 'Nhận phòng',
                icon: Icons.login,
                value: _formatDateTime(draft.checkIn),
                onTap: draft.checkInNow
                    ? null
                    : () => _pickDateTime(
                        isCheckIn: true,
                      ), // disabled if checkInNow
              ),
              const SizedBox(height: 8),
              DateTimePicker(
                label: 'Trả phòng',
                icon: Icons.logout,
                value: _formatDateTime(draft.checkOut),
                onTap: () => _pickDateTime(isCheckIn: false),
              ),
              //End section 3
              Row(
                children: [
                  Checkbox(
                    value: draft.checkInNow,
                    onChanged: (val) {
                      _bookingDraftProvider.setCheckInNow(
                        _draftKey,
                        val ?? false,
                      );
                    },
                  ),
                  const Text('Check-in ngay'),
                ],
              ), // space for bottom button
              const SizedBox(height: 100),
            ],
          ),

          // ── Bottom button ─────────────────────────────────────────
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitBooking,
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('Thu tiền cọc & đặt lịch'),
            ),
          ),
        );
      },
    );
  }
}
