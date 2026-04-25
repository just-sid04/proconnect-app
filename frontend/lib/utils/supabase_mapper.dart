/// Converts Supabase snake_case row to camelCase for model parsing (recursive)
Map<String, dynamic> supabaseRowToJson(Map<String, dynamic> row) {
  final result = <String, dynamic>{};
  for (final e in row.entries) {
    final camelKey = _snakeToCamel(e.key);
    result[camelKey] = _convertValue(e.value);
  }
  return result;
}

dynamic _convertValue(dynamic value) {
  if (value is Map) {
    return supabaseRowToJson(Map<String, dynamic>.from(value));
  }
  if (value is List) {
    return value.map(_convertValue).toList();
  }
  return value;
}

String _snakeToCamel(String s) {
  if (!s.contains('_')) return s;
  return s.split('_').fold('', (a, b) {
    if (a.isEmpty) return b.toLowerCase();
    return a + b[0].toUpperCase() + b.substring(1).toLowerCase();
  });
}

/// Converts camelCase map to snake_case for Supabase insert/update
Map<String, dynamic> jsonToSupabaseRow(Map<String, dynamic> json) {
  final result = <String, dynamic>{};
  for (final e in json.entries) {
    final snakeKey = _camelToSnake(e.key);
    result[snakeKey] = e.value;
  }
  return result;
}

String _camelToSnake(String s) {
  return s.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (m) => '_${m.group(0)!.toLowerCase()}',
  );
}
