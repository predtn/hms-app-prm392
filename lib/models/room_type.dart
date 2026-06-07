import 'dart:convert';
import 'package:hms_app/utils/safe_parser.dart';

class RoomType {
  final int id;
  final String? imageUrl;
  final String typeName;
  final int numberOfBed;
  final int pricePerNight;
  final String? description;
  final String? addOn;

  RoomType({
    required this.id,
    this.imageUrl,
    required this.typeName,
    required this.numberOfBed,
    required this.pricePerNight,
    this.description,
    this.addOn,
  });

  factory RoomType.fromJson(Map<String, dynamic> json) {
    return RoomType(
      id: parseInt(json['id']),
      imageUrl: json['image_url'] as String?,
      typeName: json['type_name'] as String,
      numberOfBed: parseInt(json['number_of_bed']),
      pricePerNight: parseInt(json['price_per_night']),
      description: json['description'] as String?,
      addOn: json['add_on'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'type_name': typeName,
      'number_of_bed': numberOfBed,
      'price_per_night': pricePerNight,
      'description': description,
      'add_on': addOn,
    };
  }

  static RoomType fromJsonString(String jsonString) =>
      RoomType.fromJson(json.decode(jsonString) as Map<String, dynamic>);

  String toJsonString() => json.encode(toJson());
}
