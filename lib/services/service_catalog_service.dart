import 'package:hms_app/models/dtos/service_usage.dart';
import 'package:hms_app/models/service.dart';
import 'package:hms_app/repositories/service_repository.dart';

class ServiceCatalogService {
  ServiceCatalogService({ServiceRepository? repository})
    : _repository = repository ?? ServiceRepository();

  final ServiceRepository _repository;

  Future<void> createService({
    required String name,
    String? description,
    required String unit,
    required int pricePerUnit,
    String? imageUrl,
    required bool status,
  }) {
    return _repository.createService(
      name: name,
      description: description,
      unit: unit,
      pricePerUnit: pricePerUnit,
      imageUrl: imageUrl,
      status: status,
    );
  }

  Future<List<Service>> getServices() => _repository.getServices();

  Future<void> deleteService(int id) => _repository.deleteService(id);

  Future<Service?> getServiceById(int id) => _repository.getServiceById(id);

  Future<void> updateService({
    required int id,
    required String name,
    String? description,
    required String unit,
    required int pricePerUnit,
    String? imageUrl,
    required bool status,
  }) {
    return _repository.updateService(
      id: id,
      name: name,
      description: description,
      unit: unit,
      pricePerUnit: pricePerUnit,
      imageUrl: imageUrl,
      status: status,
    );
  }

  Future<void> updateServiceUsage(
    int bookingId,
    List<ServiceUsage> serviceUsages,
  ) {
    return _repository.updateServiceUsage(bookingId, serviceUsages);
  }
}
