import 'package:hms_app/models/dtos/service_usage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hms_app/models/service.dart';

class ServiceRepository {
  final _supabase = Supabase.instance.client;

  Future<void> createService({
    required String name,
    String? description,
    required String unit,
    required int pricePerUnit,
    String? imageUrl,
    required bool status,
  }) async {
    await _supabase.from('services').insert({
      'name': name,
      'description': description,
      'unit': unit,
      'price_per_unit': pricePerUnit,
      'image_url': imageUrl,
      'status': status,
    });
  }

  Future<List<Service>> getServices() async {
    final response = await _supabase
        .from('services')
        .select()
        .order('id', ascending: true);

    return (response as List).map((json) => Service.fromJson(json)).toList();
  }

  Future<void> deleteService(int id) async {
    await _supabase.from('services').delete().eq('id', id);
  }

  Future<Service?> getServiceById(int id) async {
    final response = await _supabase
        .from('services')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Service.fromJson(response);
  }

  Future<void> updateService({
    required int id,
    required String name,
    String? description,
    required String unit,
    required int pricePerUnit,
    String? imageUrl,
    required bool status,
  }) async {
    await _supabase
        .from('services')
        .update({
          'name': name,
          'description': description,
          'unit': unit,
          'price_per_unit': pricePerUnit,
          'image_url': imageUrl,
          'status': status,
        })
        .eq('id', id);
  }

  Future<void> updateServiceUsage(
    int bookingId,
    List<ServiceUsage> serviceUsages,
  ) async {
    //delete old first
    await _supabase.from('service_usage').delete().eq('booking_id', bookingId);

    // insert new
    final usagesToInsert = serviceUsages.where((e) => e.quantity > 0).toList();
    if (usagesToInsert.isEmpty) return;

    await _supabase
        .from('service_usage')
        .insert(
          usagesToInsert
              .map(
                (e) => {
                  'booking_id': bookingId,
                  'service_id': e.service.id,
                  'quantity': e.quantity,
                },
              )
              .toList(),
        );
  }
}
