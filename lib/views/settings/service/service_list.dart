import 'package:flutter/material.dart';
import 'package:hms_app/models/service.dart';
import 'package:hms_app/repositories/service_repository.dart';
import 'package:hms_app/utils/format_vnd.dart';
import 'package:hms_app/views/settings/service/create_service_view.dart';

class ServiceList extends StatefulWidget {
  const ServiceList({super.key});

  @override
  State<ServiceList> createState() => _ServiceListState();
}

class _ServiceListState extends State<ServiceList> {
  final _serviceRepo = ServiceRepository();
  List<Service> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    try {
      final services = await _serviceRepo.getServices();
      setState(() {
        _services = services;
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

  Future<void> _deleteService(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa dịch vụ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _serviceRepo.deleteService(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Xóa dịch vụ thành công')));
        _loadServices();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách dịch vụ')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
          ? const Center(child: Text('Chưa có dịch vụ nào'))
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _services.length,
              itemBuilder: (context, index) {
                final service = _services[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    // side: BorderSide(color: Colors.grey.shade300, width: 1),
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
                                (service.imageUrl != null &&
                                    service.imageUrl!.isNotEmpty)
                                ? DecorationImage(
                                    image: NetworkImage(service.imageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child:
                              (service.imageUrl == null ||
                                  service.imageUrl!.isEmpty)
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
                                service.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              if (service.description != null &&
                                  service.description!.isNotEmpty)
                                Text(
                                  service.description!,
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
                              '${formatVND(service.pricePerUnit)} VND/${service.unit}',
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
                                            CreateServiceView(service: service),
                                      ),
                                    );
                                    _loadServices();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  color: Colors.red.shade400,
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  onPressed: () => _deleteService(service.id),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateServiceView()),
          );
          // Reload services after returning from the create view to see the new service
          _loadServices();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
