String normalizeDialedNumber(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  return digits;
}

bool isValidDialedNumber(String value) {
  return normalizeDialedNumber(value).length >= 3;
}

String? sanitizeLinkedPhoneNumber(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final normalized = normalizeDialedNumber(value);
  return normalized.length >= 3 ? normalized : null;
}

String formatDialedNumber(String value) {
  final digits = normalizeDialedNumber(value);
  if (digits.isEmpty) return '000';

  final groups = <String>[];
  for (var i = 0; i < digits.length; i += 3) {
    final end = (i + 3 < digits.length) ? i + 3 : digits.length;
    groups.add(digits.substring(i, end));
  }
  return groups.join(' ');
}
