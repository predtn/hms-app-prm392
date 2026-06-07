import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hms_app/utils/file_upload.dart';
import 'package:hms_app/repositories/room_type_repository.dart';
import 'package:hms_app/models/room_type.dart';

class CreateRoomTypeView extends StatefulWidget {
  final RoomType? roomType;

  const CreateRoomTypeView({super.key, this.roomType});

  @override
  State<CreateRoomTypeView> createState() => _CreateRoomTypeViewState();
}

class _CreateRoomTypeViewState extends State<CreateRoomTypeView> {
  final _formKey = GlobalKey<FormState>();
  final _roomTypeRepository = RoomTypeRepository();

  bool _isSaving = false;

  late TextEditingController _typeNameController;
  late TextEditingController _priceController;
  late TextEditingController _bedController;
  late TextEditingController _descriptionController;
  late TextEditingController _addOnsController;

  XFile? _newImageFile;

  @override
  void initState() {
    super.initState();
    _typeNameController = TextEditingController(
      text: widget.roomType?.typeName ?? '',
    );
    _priceController = TextEditingController(
      text: widget.roomType?.pricePerNight.toString() ?? '',
    );
    _bedController = TextEditingController(
      text: widget.roomType?.numberOfBed.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.roomType?.description ?? '',
    );
    _addOnsController = TextEditingController(
      text: widget.roomType?.addOn ?? '',
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newImageFile = pickedFile;
      });
    }
  }

  Future<void> _saveRoomType() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      String? uploadedImageUrl;

      if (_newImageFile != null) {
        final uploadedUrl = await uploadToStorage(_newImageFile!);
        if (uploadedUrl != null) {
          uploadedImageUrl = uploadedUrl;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không thể tải ảnh lên. Vui lòng thử lại.'),
              ),
            );
            setState(() {
              _isSaving = false;
            });
          }
          return;
        }
      }

      String? finalImageUrl = uploadedImageUrl ?? widget.roomType?.imageUrl;

      if (widget.roomType == null) {
        await _roomTypeRepository.createRoomType(
          typeName: _typeNameController.text.trim(),
          numberOfBed: int.parse(_bedController.text.trim()),
          pricePerNight: int.parse(_priceController.text.trim()),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          addOn: _addOnsController.text.trim().isEmpty
              ? null
              : _addOnsController.text.trim(),
          imageUrl: finalImageUrl,
        );
      } else {
        await _roomTypeRepository.updateRoomType(
          id: widget.roomType!.id,
          typeName: _typeNameController.text.trim(),
          numberOfBed: int.parse(_bedController.text.trim()),
          pricePerNight: int.parse(_priceController.text.trim()),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          addOn: _addOnsController.text.trim().isEmpty
              ? null
              : _addOnsController.text.trim(),
          imageUrl: finalImageUrl,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.roomType == null
                  ? 'Tạo loại phòng thành công'
                  : 'Cập nhật loại phòng thành công',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _typeNameController.dispose();
    _priceController.dispose();
    _bedController.dispose();
    _descriptionController.dispose();
    _addOnsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.roomType != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa loại phòng' : 'Thêm loại phòng mới'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Center(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: _newImageFile != null
                          ? Image(
                              image:
                                  (kIsWeb
                                          ? NetworkImage(_newImageFile!.path)
                                          : FileImage(
                                              File(_newImageFile!.path),
                                            ))
                                      as ImageProvider,
                              fit: BoxFit.cover,
                            )
                          : (widget.roomType?.imageUrl != null &&
                                widget.roomType!.imageUrl!.isNotEmpty)
                          ? Image.network(
                              widget.roomType!.imageUrl!,
                              fit: BoxFit.cover,
                            )
                          : const Center(
                              child: Icon(Icons.image_outlined, size: 64),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Thay đổi ảnh'),
                  ),
                  if (_newImageFile != null)
                    const Text(
                      '1 ảnh được chọn',
                      style: TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _typeNameController,
              decoration: const InputDecoration(
                labelText: 'Loại phòng',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên loại phòng';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Giá mỗi đêm',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập giá';
                }
                if (int.tryParse(value.trim()) == null) {
                  return 'Giá phải là số hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bedController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số lượng giường',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập số giường';
                }
                if (int.tryParse(value.trim()) == null) {
                  return 'Số giường phải là số hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Miêu tả',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addOnsController,
              decoration: const InputDecoration(
                labelText: 'Tiện ích bổ sung',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveRoomType,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
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
    );
  }
}
