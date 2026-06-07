import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:hms_app/models/user_profile.dart';
import 'package:hms_app/repositories/user_repository.dart';
import 'package:hms_app/utils/file_upload.dart';
import 'package:hms_app/widgets/app_drawer.dart';
import 'package:hms_app/providers/user_provider.dart';

class MyProfileView extends StatefulWidget {
  const MyProfileView({super.key});

  @override
  State<MyProfileView> createState() => _MyProfileViewState();
}

class _MyProfileViewState extends State<MyProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _userRepository = UserRepository();

  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  XFile? _newAvatarFile;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.userProfile == null) {
        userProvider.fetchUserProfile().then((_) {
          if (mounted) _populateFields();
        });
      } else {
        _populateFields();
      }
    });
  }

  void _populateFields() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final profile = userProvider.userProfile;
    if (profile != null) {
      _userProfile = profile;
      _fullNameController.text = profile.fullName ?? '';
      _emailController.text = profile.email ?? '';
      _phoneController.text = profile.phone ?? '';
    }
    setState(() {
      _isLoading = false;
      _newAvatarFile = null;
    });
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newAvatarFile = pickedFile;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userProfile == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      String? updatedAvatarUrl = _userProfile!.avatarUrl;

      // If a new avatar file was chosen, upload it first
      if (_newAvatarFile != null) {
        if (updatedAvatarUrl != null && updatedAvatarUrl.isNotEmpty) {
          await deleteFromStorage(updatedAvatarUrl);
        }

        final uploadedUrl = await uploadToStorage(_newAvatarFile!);
        if (uploadedUrl != null) {
          updatedAvatarUrl = uploadedUrl;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Không thể tải ảnh đại diện lên. Vui lòng thử lại.',
                ),
              ),
            );
            setState(() {
              _isSaving = false;
            });
          }
          return; // Stop saving since upload failed
        }
      }

      await _userRepository.updateUserProfile(
        id: _userProfile!.id,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        avatarUrl: updatedAvatarUrl,
      );

      // Successfully updated, trigger provider refetch
      if (mounted) {
        await Provider.of<UserProvider>(
          context,
          listen: false,
        ).fetchUserProfile();

        setState(() {
          _userProfile = Provider.of<UserProvider>(
            context,
            listen: false,
          ).userProfile;
          _newAvatarFile = null;
        });
        // 3. Since there was another async gap (await), we need one more check!
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi cập nhật thông tin: $e')));
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
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin cá nhân')),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
          ? const Center(child: Text('Không tìm thấy thông tin người dùng'))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: _newAvatarFile != null
                              ? (kIsWeb
                                        ? NetworkImage(_newAvatarFile!.path)
                                        : FileImage(File(_newAvatarFile!.path)))
                                    as ImageProvider
                              : (_userProfile?.avatarUrl != null &&
                                    _userProfile!.avatarUrl!.isNotEmpty)
                              ? NetworkImage(_userProfile!.avatarUrl!)
                              : null,
                          child:
                              (_newAvatarFile == null &&
                                  (_userProfile?.avatarUrl == null ||
                                      _userProfile!.avatarUrl!.isEmpty))
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _pickAvatar,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Chọn ảnh đại diện'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    enabled: false, // Cannot update
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập họ và tên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Lưu thay đổi'),
                  ),
                ],
              ),
            ),
    );
  }
}
