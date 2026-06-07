import 'package:hms_app/models/fee.dart';

class BillingItem {
  final String title;
  final String subtitle;
  final int price;
  final FeeType type;

  BillingItem({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.type,
  });
}
