class RoomSearchResult {
  final int id;
  final String roomName;
  final String typeName;
  final int numberOfBed;
  final String? imageUrl;
  final String? description;

  RoomSearchResult({
    required this.id,
    required this.roomName,
    required this.typeName,
    required this.numberOfBed,
    this.imageUrl,
    this.description,
  });

  factory RoomSearchResult.fromJson(Map<String, dynamic> json) {
    final roomType = json['room_types'];
    return RoomSearchResult(
      id: json['id'],
      roomName: json['room_name'],
      typeName: roomType['type_name'],
      numberOfBed: roomType['number_of_bed'],
      imageUrl: roomType['image_url'],
      description: roomType['description'],
    );
  }
}
