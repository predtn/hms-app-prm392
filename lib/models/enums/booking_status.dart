enum BookingStatus { confirmed, checkedIn, checkedOut, noShow }

extension BookingStatusExtension on BookingStatus {
  String get name {
    switch (this) {
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.checkedIn:
        return 'checked_in';
      case BookingStatus.checkedOut:
        return 'checked_out';
      case BookingStatus.noShow:
        return 'no_show';
    }
  }

  String toDatabaseValue() {
    switch (this) {
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.checkedIn:
        return 'checked_in';
      case BookingStatus.checkedOut:
        return 'checked_out';
      case BookingStatus.noShow:
        return 'no_show';
    }
  }

  static BookingStatus fromDatabaseValue(String dbValue) {
    switch (dbValue) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'checked_in':
        return BookingStatus.checkedIn;
      case 'checked_out':
        return BookingStatus.checkedOut;
      case 'no_show':
        return BookingStatus.noShow;
      default:
        throw ArgumentError('Unknown BookingStatus: $dbValue');
    }
  }
}
