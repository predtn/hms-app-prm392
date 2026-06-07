import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/room_search_result.dart';
import 'package:hms_app/models/dtos/room_type_option.dart';
import 'package:hms_app/repositories/room_type_repository.dart';
import 'package:hms_app/widgets/app_drawer.dart';
import 'package:hms_app/repositories/room_repository.dart';
import 'package:hms_app/views/booking_many_view.dart';
import 'package:hms_app/widgets/date_time_picker.dart';

class FindRoomView extends StatefulWidget {
  const FindRoomView({super.key});

  @override
  State<FindRoomView> createState() => _FindRoomViewState();
}

class _FindRoomViewState extends State<FindRoomView> {
  final RoomRepository _roomRepository = RoomRepository();
  final RoomTypeRepository _roomTypeRepository = RoomTypeRepository();
  List<RoomSearchResult> _filteredRooms = [];
  List<RoomTypeOption> _roomTypes = [];
  bool _isLoading = false;

  Set<int> selectedRoomTypeIds = {};
  Set<int> selectedRoomIds = {};
  DateTime? checkInDate;
  DateTime? checkOutDate;
  final TextEditingController bedNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRoomTypes();
  }

  @override
  void dispose() {
    bedNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadRoomTypes() async {
    try {
      final types = await _roomTypeRepository.getRoomTypeOptions();
      setState(() => _roomTypes = types);
    } catch (e) {
      debugPrint('Error loading room types: $e');
    }
  }

  void _toggleRoomType(RoomTypeOption type) {
    setState(() {
      if (selectedRoomTypeIds.contains(type.id)) {
        selectedRoomTypeIds.remove(type.id);
      } else {
        selectedRoomTypeIds.add(type.id);
      }
    });
  }

  void _toggleRoom(int roomId) {
    setState(() {
      if (selectedRoomIds.contains(roomId)) {
        selectedRoomIds.remove(roomId);
      } else {
        selectedRoomIds.add(roomId);
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final initialDate = isCheckIn
        ? (checkInDate ?? DateTime.now())
        : (checkOutDate ?? checkInDate ?? DateTime.now());
    final firstDate = isCheckIn
        ? DateTime.now()
        : (checkInDate ?? DateTime.now());

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2101),
    );

    if (pickedDate == null) return;

    final pickedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      isCheckIn ? 14 : 12,
    );

    setState(() {
      if (isCheckIn) {
        checkInDate = pickedDateTime;
        if (checkOutDate != null && checkOutDate!.isBefore(checkInDate!)) {
          checkOutDate = null;
        }
      } else {
        checkOutDate = pickedDateTime;
      }
    });
  }

  Future<void> _searchRooms() async {
    setState(() => _isLoading = true);
    try {
      final bedNumber = int.tryParse(bedNumberController.text);
      final selectedTypeNames = selectedRoomTypeIds.isEmpty
          ? null
          : _roomTypes
                .where((t) => selectedRoomTypeIds.contains(t.id))
                .map((t) => t.typeName)
                .toList();

      final rooms = await _roomRepository.searchRooms(
        numberOfBed: bedNumber,
        typeNames: selectedTypeNames,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
      );

      setState(() {
        _filteredRooms = rooms;
        selectedRoomIds.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error finding rooms: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chọn ngày';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Map<String, List<RoomSearchResult>> _groupByTypeName() {
    final map = <String, List<RoomSearchResult>>{};
    for (final room in _filteredRooms) {
      map.putIfAbsent(room.typeName, () => []).add(room);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final grouped = _groupByTypeName();

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        title: Text('Tìm Phòng', style: TextStyle(color: color.onSurface)),
        centerTitle: true,
        backgroundColor: color.surface,
        iconTheme: IconThemeData(color: color.onSurface),
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date pickers ──────────────────────────────────────────────
            DateTimePicker(
              label: 'Nhận phòng',
              icon: Icons.login,
              value: _formatDate(checkInDate),
              onTap: () => _selectDate(context, true),
            ),
            const SizedBox(height: 12),
            DateTimePicker(
              label: 'Trả phòng',
              icon: Icons.logout,
              value: _formatDate(checkOutDate),
              onTap: () => _selectDate(context, false),
            ),
            const SizedBox(height: 12),

            // ── Bed count ─────────────────────────────────────────────────
            TextField(
              controller: bedNumberController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: color.onSurface),
              decoration: InputDecoration(
                labelText: 'Giường chính',
                labelStyle: TextStyle(color: color.onSurfaceVariant),
                prefixIcon: Icon(Icons.bed, color: color.primary),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: color.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: color.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Room type filter ──────────────────────────────────────────
            Text(
              'Loại Phòng',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            if (_roomTypes.isEmpty)
              LinearProgressIndicator(color: color.primary)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _roomTypes
                    .map(
                      (type) => FilterChip(
                        label: Text(type.typeName),
                        selected: selectedRoomTypeIds.contains(type.id),
                        onSelected: (_) => _toggleRoomType(type),
                      ),
                    )
                    .toList(),
              ),

            const SizedBox(height: 24),

            // ── Search button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _searchRooms,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.primary,
                  foregroundColor: color.onPrimary,
                  disabledBackgroundColor: color.surfaceContainerHighest,
                ),
                icon: _isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color.onPrimary,
                        ),
                      )
                    : const Icon(Icons.search),
                label: const Text('Tìm kiếm'),
              ),
            ),

            const SizedBox(height: 24),
            Divider(thickness: 1, color: color.outlineVariant),
            const SizedBox(height: 12),

            // ── Results ───────────────────────────────────────────────────
            if (_isLoading)
              Center(child: CircularProgressIndicator(color: color.primary))
            else if (_filteredRooms.isEmpty)
              Center(
                child: Text(
                  'Không có phòng nào phù hợp.',
                  style: TextStyle(color: color.onSurfaceVariant),
                ),
              )
            else
              ...grouped.entries.map(
                (entry) => _RoomTypeGroup(
                  typeName: entry.key,
                  rooms: entry.value,
                  selectedRoomIds: selectedRoomIds,
                  onToggleRoom: _toggleRoom,
                  color: color,
                ),
              ),
          ],
        ),
      ),

      // ── Book button ───────────────────────────────────────────────────
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: selectedRoomIds.isNotEmpty
              ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateBookingManyScreen(
                      roomIds: selectedRoomIds,
                      checkIn: checkInDate,
                      checkOut: checkOutDate,
                    ),
                  ),
                )
              : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text(
            selectedRoomIds.isEmpty
                ? 'Đặt Phòng'
                : 'Đặt Phòng (${selectedRoomIds.length})',
          ),
        ),
      ),
    );
  }
}

// ── Room-type group card with ExpansionTile dropdown ──────────────────────────

class _RoomTypeGroup extends StatelessWidget {
  const _RoomTypeGroup({
    required this.typeName,
    required this.rooms,
    required this.selectedRoomIds,
    required this.onToggleRoom,
    required this.color,
  });

  final String typeName;
  final List<RoomSearchResult> rooms;
  final Set<int> selectedRoomIds;
  final ValueChanged<int> onToggleRoom;
  final ColorScheme color;

  int get _selectedCount =>
      rooms.where((r) => selectedRoomIds.contains(r.id)).length;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: color.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: _GroupHeader(
          rooms: rooms,
          selectedCount: _selectedCount,
          color: color,
        ),
        children: rooms
            .map(
              (room) => _RoomTile(
                room: room,
                isSelected: selectedRoomIds.contains(room.id),
                onTap: () => onToggleRoom(room.id),
                color: color,
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Header shown in the collapsed/expanded ExpansionTile title ────────────────

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.rooms,
    required this.selectedCount,
    required this.color,
  });

  final List<RoomSearchResult> rooms;
  final int selectedCount;
  final ColorScheme color;

  @override
  Widget build(BuildContext context) {
    final first = rooms.first;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: first.imageUrl != null
              ? Image.network(
                  first.imageUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      _ImagePlaceholder(color: color, size: 56),
                )
              : _ImagePlaceholder(color: color, size: 56),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                first.typeName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                selectedCount > 0
                    ? '${rooms.length} phòng · $selectedCount đã chọn'
                    : '${rooms.length} phòng trống',
                style: TextStyle(
                  fontSize: 12,
                  color: selectedCount > 0
                      ? color.primary
                      : color.onSurfaceVariant,
                ),
              ),
              if (first.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  first.description!,
                  style: TextStyle(fontSize: 12, color: color.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Individual room row inside the expanded dropdown ─────────────────────────

class _RoomTile extends StatelessWidget {
  const _RoomTile({
    required this.room,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  final RoomSearchResult room;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: color.outlineVariant.withValues(alpha: 0.4)),
            left: isSelected
                ? BorderSide(color: color.primary, width: 3)
                : BorderSide.none,
          ),
          color: isSelected ? color.primary.withValues(alpha: 0.06) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Phòng ${room.roomName}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: color.onSurface,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color.primary),
          ],
        ),
      ),
    );
  }
}

// ── Shared image placeholder ──────────────────────────────────────────────────

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.color, this.size = 80});

  final ColorScheme color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: color.surfaceContainerHighest,
      child: Icon(Icons.image_not_supported, color: color.onSurfaceVariant),
    );
  }
}
