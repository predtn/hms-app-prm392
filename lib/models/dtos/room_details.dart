class RoomDetails {
  final int id;
  final String roomName;
  final int floor;
  final String? imageUrl;
  final String typeName;
  final int numberOfBed;
  final int pricePerNight;
  final String? description;
  final String? addOn;
  RoomDetails({
    required this.id,
    required this.roomName,
    required this.floor,
    this.imageUrl,
    required this.typeName,
    required this.numberOfBed,
    required this.pricePerNight,
    this.description,
    this.addOn,
  });

  factory RoomDetails.fromJson(Map<String, dynamic> json) {
    return RoomDetails(
      id: json['id'] as int,
      roomName: json['room_name'] as String,
      floor: json['floor'] as int,
      imageUrl: json['room_types']['image_url'] as String?,
      typeName: json['room_types']['type_name'] as String,
      numberOfBed: json['room_types']['number_of_bed'] as int,
      pricePerNight: json['room_types']['price_per_night'] as int,
      description: json['room_types']['description'] as String?,
      addOn: json['room_types']['add_on'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_name': roomName,
      'floor': floor,
      'room_types': {
        'image_url': imageUrl,
        'type_name': typeName,
        'number_of_bed': numberOfBed,
        'price_per_night': pricePerNight,
        'description': description,
        'add_on': addOn,
      },
    };
  }
}
