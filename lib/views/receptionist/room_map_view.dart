import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/room_card_item.dart';
import 'package:hms_app/repositories/room_repository.dart';
import 'package:hms_app/utils/app_dialogs.dart';
import 'package:hms_app/widgets/app_drawer.dart';
import 'package:hms_app/views/receptionist/widgets/room_card.dart';

enum RoomFilter {
  all('Tất cả'),
  empty('Trống'),
  reserved('Đã đặt'),
  occupied('Đang SD');

  final String label;
  const RoomFilter(this.label);
}

class RoomMapView extends StatefulWidget {
  const RoomMapView({super.key});

  @override
  State<RoomMapView> createState() => _RoomMapViewState();
}

class _RoomMapViewState extends State<RoomMapView> {
  RoomFilter _selectedFilter = RoomFilter.all;

  final _roomRepository = RoomRepository();
  List<RoomCardItem> _rooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  List<RoomCardItem> get _filteredRooms {
    return _rooms;
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final rooms = switch (_selectedFilter) {
        RoomFilter.all => await _roomRepository.getRoomMap(),
        RoomFilter.empty => await _roomRepository.getAvailableRoomMap(),
        RoomFilter.reserved => await _roomRepository.getReservedRoomMap(),
        RoomFilter.occupied => await _roomRepository.getUsingRoomMap(),
      };
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        await showErrorDialog(context, 'Lỗi tải danh sách phòng: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách phòng'),
        centerTitle: true,
        backgroundColor: color.surface,
        iconTheme: IconThemeData(color: color.onSurface),
        elevation: 0,
        actions: [IconButton(onPressed: _loadRooms, icon: Icon(Icons.refresh))],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // ── Filter ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: RoomFilter.values.map((filter) {
                final isSelected = filter == _selectedFilter;
                return FilterChip(
                  label: Text(filter.label),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedFilter = filter);
                    _loadRooms();
                  },
                );
              }).toList(),
            ),
          ),

          // ── Room grid ──────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadRooms,
                    child: _filteredRooms.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 100),
                              Center(child: Text('Không có phòng nào')),
                            ],
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      MediaQuery.sizeOf(context).width >= 900
                                      ? 4
                                      : MediaQuery.sizeOf(context).width >= 600
                                      ? 3
                                      : 2,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: 0.72,
                                ),
                            itemCount: _filteredRooms.length,
                            itemBuilder: (context, index) =>
                                RoomCard(room: _filteredRooms[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
