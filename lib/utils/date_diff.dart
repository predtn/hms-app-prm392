bool dateDiffAtLeastOne(DateTime checkIn, DateTime checkOut) {
  final checkInDate = DateTime(checkIn.year, checkIn.month, checkIn.day);
  final checkOutDate = DateTime(checkOut.year, checkOut.month, checkOut.day);

  return checkOutDate.difference(checkInDate).inDays < 1;
}
