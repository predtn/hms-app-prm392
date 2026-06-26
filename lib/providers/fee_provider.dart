import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/billing_item.dart';
import 'package:hms_app/models/fee.dart';
import 'package:hms_app/services/fee_service.dart';

class FeeProvider extends ChangeNotifier {
  FeeProvider({FeeService? service}) : _service = service ?? FeeService();

  final FeeService _service;

  Future<List<Fee>> getFeesByBookingId(int bookingId) {
    return _service.getFeesByBookingId(bookingId);
  }

  Future<void> addFees(List<BillingItem> billingItems, int bookingId) {
    return _service.addFees(billingItems, bookingId);
  }
}
