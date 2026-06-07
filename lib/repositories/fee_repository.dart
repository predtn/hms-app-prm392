import 'package:hms_app/models/dtos/billing_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hms_app/models/fee.dart';

class FeeRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Fee>> getFeesByBookingId(int bookingId) async {
    final response = await _supabase
        .from('fees')
        .select('*')
        .eq('booking_id', bookingId);
    return response.map((json) => Fee.fromJson(json)).toList();
  }

  Future<void> addFees(List<BillingItem> billingItems, int bookingId) async {
    final rows = billingItems
        .map(
          (item) => {
            'booking_id': bookingId,
            'title': item.title,
            'total_price': item.price,
            'subtitle': item.subtitle,
            'type': item.type.toDatabaseValue(),
          },
        )
        .toList();

    await _supabase.from('fees').insert(rows);
  }
}
