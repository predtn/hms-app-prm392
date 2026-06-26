import 'package:hms_app/models/dtos/booking_schedule_item.dart';

class ReceptionTaskData {
  final List<BookingScheduleItem> checkins;
  final List<BookingScheduleItem> checkouts;

  const ReceptionTaskData({required this.checkins, required this.checkouts});
}
