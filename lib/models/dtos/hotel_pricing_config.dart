class HotelPricingConfig {
  final int graceMinutes;
  final double penaltyUnder6Hours;
  final double penaltyUnder12Hours;
  final double penaltyOver12Hours;

  const HotelPricingConfig({
    this.graceMinutes = 15,
    this.penaltyUnder6Hours = 0.25,
    this.penaltyUnder12Hours = 0.50,
    this.penaltyOver12Hours = 1.0,
  });
}
