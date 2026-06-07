class CustomerShortDetail {
  final String userId;
  final String? avatar;
  final String name;
  final String phone;

  CustomerShortDetail({
    required this.userId,
    this.avatar,
    required this.name,
    required this.phone,
  });

  factory CustomerShortDetail.fromJson(Map<String, dynamic> json) {
    return CustomerShortDetail(
      userId: json['id'],
      avatar: json['avatar_url'] ?? '',
      name: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}
