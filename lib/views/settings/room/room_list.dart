import 'package:flutter/material.dart';
import 'package:hms_app/models/room.dart';
import 'package:hms_app/repositories/room_repository.dart';
import 'package:hms_app/views/settings/room/add_room.dart';

class RoomList extends StatefulWidget {
  const RoomList({super.key});

  @override
  State<RoomList> createState() => _RoomListState();
}

class _RoomListState extends State<RoomList> {
  final RoomRepository _roomRepository = RoomRepository();
  List<Room> _rooms = [];
  List<Room> _filteredRooms = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRooms();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    try {
      final rooms = await _roomRepository.fetchRooms();
      setState(() {
        _rooms = rooms;
        _filteredRooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRooms = _rooms.where((r) {
        return r.roomName.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _deleteRoom(int id) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa phòng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _roomRepository.deleteRoom(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Xóa phòng thành công')));
        _loadRooms();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách phòng')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadRooms,
                    child: _filteredRooms.isEmpty
                        ? const Center(child: Text('Không tìm thấy phòng nào'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(8.0),
                            itemCount: _filteredRooms.length,
                            itemBuilder: (context, index) {
                              final room = _filteredRooms[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 8,
                                ),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(width: 16),
                                      // Middle Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              room.roomName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Tầng ${room.floor}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Right Side (Buttons)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              size: 20,
                                            ),
                                            color: Colors.grey.shade700,
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(8),
                                            onPressed: () async {
                                              final result =
                                                  await Navigator.pushNamed(
                                                    context,
                                                    '/edit-room/${room.id}',
                                                  );
                                              if (result == true) {
                                                _loadRooms();
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              size: 20,
                                            ),
                                            color: Colors.red.shade400,
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(8),
                                            onPressed: () {
                                              _deleteRoom(room.id);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddRoom()),
          );
          if (result == true) {
            _loadRooms();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
