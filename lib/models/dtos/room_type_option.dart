class RoomTypeOption {
  final int id;
  final String typeName;

  const RoomTypeOption({required this.id, required this.typeName});

  factory RoomTypeOption.fromJson(Map<String, dynamic> json) =>
      RoomTypeOption(id: json['id'], typeName: json['type_name']);
}
