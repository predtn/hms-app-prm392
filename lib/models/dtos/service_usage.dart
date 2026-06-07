import 'package:hms_app/models/service.dart';

class ServiceUsage {
  final Service service;
  final int quantity;

  ServiceUsage({required this.service, required this.quantity});

  factory ServiceUsage.fromJson(Map<String, dynamic> json) {
    final quantity = (json['service_usage'] as List).isEmpty
        ? 0
        : (json['service_usage'] as List)[0]['quantity'] as int;
    return ServiceUsage(service: Service.fromJson(json), quantity: quantity);
  }
}
