import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/customer_short_detail.dart';
import 'package:hms_app/models/dtos/room_details.dart';
import 'package:hms_app/repositories/booking_repository.dart';
import 'package:hms_app/repositories/room_repository.dart';
import 'package:hms_app/repositories/user_repository.dart';
import 'package:hms_app/utils/date_diff.dart';
import 'package:hms_app/utils/format_vnd.dart';
import 'package:hms_app/widgets/date_time_picker.dart';

class CreateBookingManyScreen extends StatefulWidget {
  const CreateBookingManyScreen({
    super.key,
    required this.roomIds,
    this.checkIn,
    this.checkOut,
  });

  final Set<int> roomIds;
  final DateTime? checkIn;
  final DateTime? checkOut;

  @override
  State<CreateBookingManyScreen> createState() =>
      _CreateBookingManyScreenState();
}

class _CreateBookingManyScreenState extends State<CreateBookingManyScreen> {
  late Future<List<RoomDetails>> _roomDetailsFuture;
  final _roomRepository = RoomRepository();
  final _bookingRepository = BookingRepository();
  final _userRepository = UserRepository();

  final _guestNameController = TextEditingController();
  final _phoneController = TextEditingController();
  late Future<List<CustomerShortDetail>> _customersFuture;
  bool _isNewCustomer = true;
  CustomerShortDetail? _selectedCustomer;
  bool _checkInNow = false;
  DateTime? _checkIn;
  DateTime? _checkOut;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _checkIn = widget.checkIn;
    _checkOut = widget.checkOut;
    _roomDetailsFuture = Future.wait(
      widget.roomIds.map((id) => _roomRepository.getRoomDetails(id)),
    );
    _customersFuture = _userRepository.getAllCustomers();
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    _phoneController.dispose();
    super.dispose();
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

    setState(() {
      if (isCheckIn) {
        _checkIn = result;
      } else {
        _checkOut = result;
      }
    });
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Chưa chọn';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submitBooking() async {
    final String name;
    final String phone;

    if (_isNewCustomer) {
      name = _guestNameController.text.trim();
      phone = _phoneController.text.trim();
    } else {
      name = _selectedCustomer?.name ?? '';
      phone = _selectedCustomer?.phone ?? '';
    }

    if (name.isEmpty ||
        phone.isEmpty ||
        _checkIn == null ||
        _checkOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isNewCustomer
                ? 'Vui lòng điền đầy đủ thông tin'
                : 'Vui lòng chọn khách và điền thời gian',
          ),
        ),
      );
      return;
    }

    if (dateDiffAtLeastOne(_checkIn!, _checkOut!)) {
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
      if (_isNewCustomer) {
        userId = await _userRepository.getNewlyCreatedCustomerId(name, phone);
      } else {
        userId = _selectedCustomer!.userId;
      }

      // Create a booking for each selected room
      for (final roomId in widget.roomIds) {
        await _bookingRepository.createBooking(
          roomId: roomId,
          userId: userId,
          checkInDateTime: _checkIn!,
          checkOutDateTime: _checkOut!,
          checkInNow: _checkInNow,
        );
      }
      if (mounted) {
        final customer = CustomerShortDetail(
          userId: userId,
          name: name,
          phone: phone,
        );
        Navigator.of(context).pushReplacementNamed('/find-customer');
        Navigator.of(context).pushNamed(
          '/customer-bookings/$userId',
          arguments: customer,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tạo booking: $e')));
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
    return FutureBuilder<List<RoomDetails>>(
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
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Không tìm thấy')),
            body: const Center(child: Text('Không tìm thấy phòng')),
          );
        }

        final rooms = snapshot.data!;

        return Scaffold(
          appBar: AppBar(title: Text('Đặt ${rooms.length} phòng')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Section 1: Room details (expandable) ──
              Card(
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  initiallyExpanded: true,
                  leading: const Icon(Icons.bed),
                  title: Text(
                    '${rooms.length} phòng đã chọn',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${formatVND(rooms.fold(0, (sum, r) => sum + r.pricePerNight))} VND/đêm',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: rooms
                      .map(
                        (room) => Column(
                          children: [
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: room.imageUrl != null
                                        ? Image.network(
                                            room.imageUrl!,
                                            width: 64,
                                            height: 64,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                _imagePlaceholder(),
                                          )
                                        : _imagePlaceholder(),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Phòng ${room.roomName} - ${room.typeName}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.bed,
                                              size: 13,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${room.numberOfBed} giường  •  Tầng ${room.floor}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${formatVND(room.pricePerNight)} VND/đêm',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),

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
                    isSelected: [_isNewCustomer, !_isNewCustomer],
                    onPressed: (index) {
                      setState(() {
                        _isNewCustomer = index == 0;
                      });
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
              if (_isNewCustomer) ...[
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
                      onSelected: (value) =>
                          setState(() => _selectedCustomer = value),
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
                // Selected customer card
                if (_selectedCustomer != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    // color: Theme.of(context).colorScheme.primaryContainer,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            _selectedCustomer!.avatar?.isNotEmpty == true
                            ? NetworkImage(_selectedCustomer!.avatar!)
                            : null,
                        child: _selectedCustomer!.avatar?.isNotEmpty == true
                            ? null
                            : Text(
                                _selectedCustomer!.name.isNotEmpty
                                    ? _selectedCustomer!.name[0].toUpperCase()
                                    : '?',
                              ),
                      ),
                      title: Text(
                        _selectedCustomer!.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(_selectedCustomer!.phone),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Bỏ chọn',
                        onPressed: () =>
                            setState(() => _selectedCustomer = null),
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
                value: _formatDateTime(_checkIn),
                onTap: _checkInNow
                    ? null
                    : () => _pickDateTime(
                        isCheckIn: true,
                      ), // disabled if checkInNow
              ),
              const SizedBox(height: 8),
              DateTimePicker(
                label: 'Trả phòng',
                icon: Icons.logout,
                value: _formatDateTime(_checkOut),
                onTap: () => _pickDateTime(isCheckIn: false),
              ),
              //End section 3
              Row(
                children: [
                  Checkbox(
                    value: _checkInNow,
                    onChanged: (val) {
                      setState(() {
                        _checkInNow = val ?? false;
                        if (_checkInNow) {
                          _checkIn = DateTime.now();
                        }
                      });
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

  Widget _imagePlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: Colors.grey[300],
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }
}
