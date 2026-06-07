import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/hotel_pricing_config.dart';

class PricingConfigProvider extends ChangeNotifier {
  // Initialize with the standard defaults
  HotelPricingConfig _config = const HotelPricingConfig();

  HotelPricingConfig get config => _config;

  // Allows the UI to update one or multiple settings at a time
  void updateConfig({
    int? graceMinutes,
    double? penaltyUnder6Hours,
    double? penaltyUnder12Hours,
    double? penaltyOver12Hours,
  }) {
    _config = HotelPricingConfig(
      graceMinutes: graceMinutes ?? _config.graceMinutes,
      penaltyUnder6Hours: penaltyUnder6Hours ?? _config.penaltyUnder6Hours,
      penaltyUnder12Hours: penaltyUnder12Hours ?? _config.penaltyUnder12Hours,
      penaltyOver12Hours: penaltyOver12Hours ?? _config.penaltyOver12Hours,
    );
    notifyListeners();
  }
}
