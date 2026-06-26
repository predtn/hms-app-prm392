import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/service_usage.dart';
import 'package:hms_app/models/service.dart';
import 'package:hms_app/services/service_catalog_service.dart';

class ServiceCatalogProvider extends ChangeNotifier {
  ServiceCatalogProvider({ServiceCatalogService? service})
    : _service = service ?? ServiceCatalogService();

  final ServiceCatalogService _service;

  Future<void> createService({
    required String name,
    String? description,
    required String unit,
    required int pricePerUnit,
    String? imageUrl,
    required bool status,
  }) {
    return _service.createService(
      name: name,
      description: description,
      unit: unit,
      pricePerUnit: pricePerUnit,
      imageUrl: imageUrl,
      status: status,
    );
  }

  Future<List<Service>> getServices() => _service.getServices();

  Future<void> deleteService(int id) => _service.deleteService(id);

  Future<Service?> getServiceById(int id) => _service.getServiceById(id);

  Future<void> updateService({
    required int id,
    required String name,
    String? description,
    required String unit,
    required int pricePerUnit,
    String? imageUrl,
    required bool status,
  }) {
    return _service.updateService(
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
    return _service.updateServiceUsage(bookingId, serviceUsages);
  }
}
