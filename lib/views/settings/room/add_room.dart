import 'package:flutter/material.dart';
import 'package:hms_app/models/room.dart';
import 'package:hms_app/repositories/room_repository.dart';
import 'package:hms_app/repositories/room_type_repository.dart';
import 'package:hms_app/models/dtos/room_type_option.dart';

class AddRoom extends StatefulWidget {
  final int? roomId;

  const AddRoom({super.key, this.roomId});

  @override
  State<AddRoom> createState() => _AddRoomState();
}

class _AddRoomState extends State<AddRoom> {
  final _formKey = GlobalKey<FormState>();
  final _roomRepository = RoomRepository();
  final _roomTypeRepository = RoomTypeRepository();

  final _floorController = TextEditingController();
  final _roomNameController = TextEditingController();

  RoomTypeOption? _selectedRoomType;
  List<RoomTypeOption> _roomTypeOptions = [];
  bool _isLoadingTypes = true;
  bool _isSubmitting = false;
  bool get isEditing => widget.roomId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _floorController.dispose();
    _roomNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final options = await _roomTypeRepository.getRoomTypeOptions();
      setState(() {
        _roomTypeOptions = options;
      });

      if (isEditing) {
        final room = await _roomRepository.getRoomById(widget.roomId!);
        _roomNameController.text = room.roomName;
        _floorController.text = room.floor.toString();

        try {
          _selectedRoomType = _roomTypeOptions.firstWhere(
            (option) => option.id == room.roomTypeId,
          );
        } catch (_) {}
      }

      setState(() {
        _isLoadingTypes = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTypes = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoomType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn loại phòng')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (isEditing) {
        final updatedRoom = Room(
          id: widget.roomId!,
          roomName: _roomNameController.text.trim(),
          roomTypeId: _selectedRoomType!.id,
          floor: int.parse(_floorController.text.trim()),
        );
        await _roomRepository.updateRoom(updatedRoom);
      } else {
        final newRoom = Room(
          id: 0, // Ignored by the database usually or omit for insert
          roomName: _roomNameController.text.trim(),
          roomTypeId: _selectedRoomType!.id,
          floor: int.parse(_floorController.text.trim()),
        );
        await _roomRepository.createRoom(newRoom);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Cập nhật phòng thành công' : 'Thêm phòng thành công',
            ),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi thêm phòng: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Cập nhật phòng' : 'Thêm phòng mới'),
      ),
      body: _isLoadingTypes
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _floorController,
                      decoration: const InputDecoration(
                        labelText: 'Tầng',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tầng';
                        }
                        final floorNum = int.tryParse(value);
                        if (floorNum == null || floorNum < 1) {
                          return 'Tầng phải là số nguyên và lớn hơn 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _roomNameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên phòng',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tên phòng';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<RoomTypeOption>(
                      decoration: const InputDecoration(
                        labelText: 'Loại phòng',
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      initialValue: _selectedRoomType,
                      items: _roomTypeOptions.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(option.typeName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRoomType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Vui lòng chọn loại phòng';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEditing ? 'Cập Nhật' : 'Tạo Mới'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
