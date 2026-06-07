import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hms_app/utils/file_upload.dart';
import 'package:hms_app/repositories/service_repository.dart';
import 'package:hms_app/models/service.dart';

class CreateServiceView extends StatefulWidget {
  final Service? service;

  const CreateServiceView({super.key, this.service});

  @override
  State<CreateServiceView> createState() => _CreateServiceViewState();
}

class _CreateServiceViewState extends State<CreateServiceView> {
  final _formKey = GlobalKey<FormState>();
  final _serviceRepository = ServiceRepository();

  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _unitController;
  late TextEditingController _priceController;
  bool _status = true;

  XFile? _newImageFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.service?.description ?? '',
    );
    _unitController = TextEditingController(text: widget.service?.unit ?? '');
    _priceController = TextEditingController(
      text: widget.service?.pricePerUnit.toString() ?? '',
    );
    if (widget.service != null) {
      _status = widget.service!.status;
    }
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

  Future<void> _saveService() async {
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
                content: Text(
                  'Không thể tải ảnh dịch vụ lên. Vui lòng thử lại.',
                ),
              ),
            );
            setState(() {
              _isSaving = false;
            });
          }
          return;
        }
      }

      String? finalImageUrl = uploadedImageUrl ?? widget.service?.imageUrl;

      if (widget.service == null) {
        await _serviceRepository.createService(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          unit: _unitController.text.trim(),
          pricePerUnit: int.parse(_priceController.text.trim()),
          imageUrl: finalImageUrl,
          status: _status,
        );
      } else {
        await _serviceRepository.updateService(
          id: widget.service!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          unit: _unitController.text.trim(),
          pricePerUnit: int.parse(_priceController.text.trim()),
          imageUrl: finalImageUrl,
          status: _status,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.service == null
                  ? 'Tạo dịch vụ thành công'
                  : 'Cập nhật dịch vụ thành công',
            ),
          ),
        );
        Navigator.pop(context); // Go back after success
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
    _nameController.dispose();
    _descriptionController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.service != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Cập nhật Dịch Vụ' : 'Thêm Dịch Vụ Mới'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(16),
                      image: _newImageFile != null
                          ? DecorationImage(
                              image:
                                  (kIsWeb
                                          ? NetworkImage(_newImageFile!.path)
                                          : FileImage(
                                              File(_newImageFile!.path),
                                            ))
                                      as ImageProvider,
                              fit: BoxFit.cover,
                            )
                          : (widget.service?.imageUrl != null &&
                                widget.service!.imageUrl!.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(widget.service!.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child:
                        (_newImageFile == null &&
                            (widget.service?.imageUrl == null ||
                                widget.service!.imageUrl!.isEmpty))
                        ? const Icon(Icons.image, size: 60, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Chọn ảnh dịch vụ'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên dịch vụ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên dịch vụ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Đơn giá',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập đơn giá';
                }
                if (int.tryParse(value.trim()) == null) {
                  return 'Đơn giá phải là số hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _unitController,
              decoration: const InputDecoration(
                labelText: 'Đơn vị tính',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bắt buộc';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Đang hoạt động'),
              value: _status,
              onChanged: (val) {
                setState(() {
                  _status = val;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveService,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Cập nhật dịch vụ' : 'Tạo dịch vụ'),
            ),
          ],
        ),
      ),
    );
  }
}
