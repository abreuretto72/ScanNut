
/// Safely casts or converts a [Map] of unknown types into a [Map<String, dynamic>].
/// Handles nested [Map]s and [List]s recursively.
Map<String, dynamic> deepCastMap(dynamic input) {
  if (input == null) return {};
  if (input is! Map) {
    throw Exception('Object is not a Map (actual type: ${input.runtimeType})');
  }

  final Map<String, dynamic> result = {};
  input.forEach((key, value) {
    final String stringKey = key.toString();
    result[stringKey] = _deepCastValue(value);
  });
  return result;
}

dynamic _deepCastValue(dynamic value) {
  if (value is Map) {
    return deepCastMap(value);
  } else if (value is List) {
    return value.map((item) => _deepCastValue(item)).toList();
  }
  return value;
}

/// Safely casts a list of objects, ensuring each Map inside is cast.
List<Map<String, dynamic>> deepCastMapList(dynamic input) {
  if (input == null) return [];
  if (input is! List) {
     throw Exception('Object is not a List (actual type: ${input.runtimeType})');
  }
  return input.map((item) => deepCastMap(item)).toList();
}
