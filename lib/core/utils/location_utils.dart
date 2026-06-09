class LocationUtils {
  static String normalizeDisplay(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    return trimmed
        .split(RegExp(r'\s+'))
        .map((part) {
          final lower = part.toLowerCase();
          return lower.isEmpty
              ? ''
              : '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .where((part) => part.isNotEmpty)
        .join(' ');
  }

  static String normalizeKey(String value) {
    return value.trim().toLowerCase();
  }

  static bool equalsIgnoreCase(String a, String b) {
    return normalizeKey(a) == normalizeKey(b);
  }

  static String? readStringField(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key)) {
        final value = data[key];
        if (value is String) return value;
        if (value != null) return value.toString();
      }
    }
    return null;
  }
}
