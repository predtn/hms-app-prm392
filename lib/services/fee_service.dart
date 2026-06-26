import 'package:hms_app/models/dtos/billing_item.dart';
import 'package:hms_app/models/fee.dart';
import 'package:hms_app/repositories/fee_repository.dart';

class FeeService {
  FeeService({FeeRepository? repository})
    : _repository = repository ?? FeeRepository();

  final FeeRepository _repository;

  Future<List<Fee>> getFeesByBookingId(int bookingId) {
    return _repository.getFeesByBookingId(bookingId);
  }

  Future<void> addFees(List<BillingItem> billingItems, int bookingId) {
    return _repository.addFees(billingItems, bookingId);
  }
}
