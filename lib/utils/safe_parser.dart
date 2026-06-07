// Safe int parser to handle ints coming as String or num
int parseInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.parse(value);
  if (value is double) return value.toInt();
  throw FormatException('Cannot parse value to int: $value');
}

bool parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) {
    final v = value.toLowerCase();
    return v == 'true' || v == '1' || v == 't' || v == 'yes';
  }
  throw FormatException('Cannot parse value to bool: $value');
}
