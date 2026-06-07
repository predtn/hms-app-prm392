import 'package:hms_app/models/dtos/hotel_pricing_config.dart';

class HotelPriceBreakdown {
  final int coreRoomFee;
  final int extraFeeForCheckIn;
  final int extraFeeForCheckOut;

  const HotelPriceBreakdown({
    required this.coreRoomFee,
    required this.extraFeeForCheckIn,
    required this.extraFeeForCheckOut,
  });

  int get total => coreRoomFee + extraFeeForCheckIn + extraFeeForCheckOut;
}

/// Calculates hotel price breakdown based on actual check-in/out times.
///
/// Standard times:
///   - Check-in:  14:00
///   - Check-out: 12:00
///
/// [checkInDateTime]       Booked check-in date (time ignored, always 14:00)
/// [checkOutDateTime]      Booked check-out date (time ignored, always 12:00)
/// [actualCheckInDateTime] Actual time guest arrived (null = arrived on time at 14:00)
/// [actualCheckOutDateTime]Actual time guest left    (null = left on time at 12:00)
/// [pricePerNight]         Room price per night in smallest currency unit
/// [graceMinutes]          Tolerance window before surcharge applies (default: 15 min)
///
/// Edge cases:
///
/// 1. Early check-in surcharge:
///    - Within grace period (≤15 min early)  → no charge
///    - 15 min – 6 hours early               → 25% of pricePerNight
///    - 6 – 12 hours early                   → 50% of pricePerNight
///    - More than 12 hours early             → 100% of pricePerNight
///
/// 2. Late check-out surcharge:
///    - Within grace period (≤15 min late)   → no charge
///    - 15 min – 6 hours late                → 25% of pricePerNight
///    - 6 – 12 hours late                    → 50% of pricePerNight
///    - More than 12 hours late              → 100% of pricePerNight
///
/// 3. Early check-out (guest leaves before standard 12:00):
///    - Guest pays full fee for booked dates. No refund/deduction for leaving early.
///
/// 4. Minimum 1 night:
///    - Even if date diff is 0 (same-day booking), at least 1 night is charged.
///
/// 5. Late check-in (guest arrives after standard 14:00):
///    - No surcharge, no discount.
HotelPriceBreakdown calculateHotelPrice({
  required DateTime checkInDateTime,
  required DateTime checkOutDateTime,
  DateTime? actualCheckInDateTime,
  DateTime? actualCheckOutDateTime,
  required int pricePerNight,
  required HotelPricingConfig config,
}) {
  final DateTime standardCheckIn = DateTime(
    checkInDateTime.year,
    checkInDateTime.month,
    checkInDateTime.day,
    14,
  );
  final DateTime standardCheckOut = DateTime(
    checkOutDateTime.year,
    checkOutDateTime.month,
    checkOutDateTime.day,
    12,
  );

  final DateTime actualIn = actualCheckInDateTime ?? standardCheckIn;
  final DateTime actualOut = actualCheckOutDateTime ?? standardCheckOut;

  // ----- Core room fee (Unchanged) -----
  final DateTime bookedCheckInDateOnly = DateTime(
    checkInDateTime.year,
    checkInDateTime.month,
    checkInDateTime.day,
  );
  final DateTime bookedCheckOutDateOnly = DateTime(
    checkOutDateTime.year,
    checkOutDateTime.month,
    checkOutDateTime.day,
  );

  int nights = bookedCheckOutDateOnly.difference(bookedCheckInDateOnly).inDays;
  if (nights < 1) nights = 1;
  final int coreRoomFee = nights * pricePerNight;

  // ----- Early check-in fee -----
  int extraFeeForCheckIn = 0;
  if (actualIn.isBefore(standardCheckIn)) {
    final Duration early = standardCheckIn.difference(actualIn);
    if (early.inMinutes > config.graceMinutes) {
      final double earlyHours = early.inMinutes / 60.0;
      if (earlyHours <= 6) {
        extraFeeForCheckIn = (pricePerNight * config.penaltyUnder6Hours)
            .round();
      } else if (earlyHours <= 12) {
        extraFeeForCheckIn = (pricePerNight * config.penaltyUnder12Hours)
            .round();
      } else {
        extraFeeForCheckIn = (pricePerNight * config.penaltyOver12Hours)
            .round();
      }
    }
  }

  // ----- Late check-out fee -----
  int extraFeeForCheckOut = 0;
  if (actualOut.isAfter(standardCheckOut)) {
    final Duration late = actualOut.difference(standardCheckOut);
    if (late.inMinutes > config.graceMinutes) {
      final double lateHours = late.inMinutes / 60.0;
      if (lateHours <= 6) {
        extraFeeForCheckOut = (pricePerNight * config.penaltyUnder6Hours)
            .round();
      } else if (lateHours <= 12) {
        extraFeeForCheckOut = (pricePerNight * config.penaltyUnder12Hours)
            .round();
      } else {
        extraFeeForCheckOut = (pricePerNight * config.penaltyOver12Hours)
            .round();
      }
    }
  }

  return HotelPriceBreakdown(
    coreRoomFee: coreRoomFee,
    extraFeeForCheckIn: extraFeeForCheckIn,
    extraFeeForCheckOut: extraFeeForCheckOut,
  );
}
