import 'package:flutter/material.dart';
import 'package:hms_app/models/room_type.dart';
import 'package:hms_app/repositories/room_type_repository.dart';
import 'package:hms_app/utils/format_vnd.dart';
import 'package:hms_app/views/settings/room_type/create_room_type.dart';

class RoomTypeList extends StatefulWidget {
  const RoomTypeList({super.key});

  @override
  State<RoomTypeList> createState() => _RoomTypeListState();
}

class _RoomTypeListState extends State<RoomTypeList> {
  final _roomTypeRepo = RoomTypeRepository();
  List<RoomType> _roomTypes = [];
  List<RoomType> _filteredRoomTypes = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRoomTypes();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRoomTypes() async {
    setState(() => _isLoading = true);
    try {
      final roomTypes = await _roomTypeRepo.getRoomTypes();
      setState(() {
        _roomTypes = roomTypes;
        _filteredRoomTypes = roomTypes;
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
      _filteredRoomTypes = _roomTypes.where((rt) {
        return rt.typeName.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _deleteRoomType(int id) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa loại phòng này?'),
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
      await _roomTypeRepo.deleteRoomType(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa loại phòng thành công')),
        );
        _loadRoomTypes();
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
      appBar: AppBar(
        title: const Text(
          'Cài đặt Loại Phòng',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        elevation: 0,
      ),
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
                : _filteredRoomTypes.isEmpty
                ? const Center(child: Text('Không tìm thấy loại phòng nào'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _filteredRoomTypes.length,
                    itemBuilder: (context, index) {
                      final roomType = _filteredRoomTypes[index];
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Image
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                  image:
                                      (roomType.imageUrl != null &&
                                          roomType.imageUrl!.isNotEmpty)
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            roomType.imageUrl!,
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child:
                                    (roomType.imageUrl == null ||
                                        roomType.imageUrl!.isEmpty)
                                    ? const Icon(
                                        Icons.image,
                                        size: 40,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              // Middle Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      roomType.typeName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${roomType.numberOfBed} giường',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    if (roomType.description != null &&
                                        roomType.description!.isNotEmpty)
                                      Text(
                                        roomType.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Right Side (Price & Buttons)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${formatVND(roomType.pricePerNight)} đ / đêm',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        color: Colors.grey.shade700,
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CreateRoomTypeView(
                                                    roomType: roomType,
                                                  ),
                                            ),
                                          );
                                          _loadRoomTypes();
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 20,
                                        ),
                                        color: Colors.red.shade400,
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                        onPressed: () =>
                                            _deleteRoomType(roomType.id),
                                      ),
                                    ],
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateRoomTypeView()),
          );
          _loadRoomTypes();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
