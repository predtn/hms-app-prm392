import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/room_card_item.dart';
import 'package:hms_app/repositories/room_repository.dart';
import 'package:hms_app/widgets/app_drawer.dart';
import 'package:hms_app/widgets/room_card.dart';

enum RoomFilter {
  all('Tất cả'),
  empty('Trống'),
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
    return _rooms.where((room) {
      return switch (_selectedFilter) {
        RoomFilter.all => true,
        RoomFilter.empty => room.status == RoomStatus.available,
        RoomFilter.occupied => room.status == RoomStatus.using,
      };
    }).toList();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true; // 👈 add this
    });
    try {
      final rooms = await _roomRepository.getRoomMap();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải danh sách phòng: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sơ đồ phòng'),
        actions: [
          IconButton(onPressed: _loadRooms, icon: const Icon(Icons.refresh)),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // ── Bộ lọc ──────────────────────────────────────────────
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
                  onSelected: (_) => setState(() => _selectedFilter = filter),
                );
              }).toList(),
            ),
          ),

          // ── Lưới phòng ──────────────────────────────────────────
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
                              vertical: 8,
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.1,
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
