import 'dart:convert';
import 'package:hms_app/utils/safe_parser.dart';

class Service {
  final int id;
  final String name;
  final String? description;
  final String unit;
  final int pricePerUnit;
  final String? imageUrl;
  final bool status;

  Service({
    required this.id,
    required this.name,
    this.description,
    required this.unit,
    required this.pricePerUnit,
    this.imageUrl,
    required this.status,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: parseInt(json['id']),
      name: json['name'] as String,
      description: json['description'] as String?,
      unit: json['unit'] as String,
      pricePerUnit: parseInt(json['price_per_unit']),
      imageUrl: json['image_url'] as String?,
      status: parseBool(json['status']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'unit': unit,
    'price_per_unit': pricePerUnit,
    'image_url': imageUrl,
    'status': status,
  };

  // Convenience helpers
  static Service fromJsonString(String jsonString) =>
      Service.fromJson(json.decode(jsonString) as Map<String, dynamic>);

  String toJsonString() => json.encode(toJson());

  Service copyWith({
    int? id,
    String? name,
    String? description,
    String? unit,
    int? pricePerUnit,
    String? imageUrl,
    bool? status,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'Service(id: $id, name: $name, description: $description, unit: $unit, pricePerUnit: $pricePerUnit, imageUrl: $imageUrl, status: $status)';
  }
}
