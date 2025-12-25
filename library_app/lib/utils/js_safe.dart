// Helper utilities to safely convert JS interop objects (LegacyJavaScriptObject) or
// other dynamic values into Dart-native types suitable for rendering in the
// widget tree and diagnostics.
//
// Why: When JS interop objects make it into widget fields (Text, ListTile, debug
// properties), the widget inspector / devtools may try to convert them to
// DiagnosticsNodes which throws the error seen during hot reload/restart:
// "TypeError: Instance of 'LegacyJavaScriptObject': type 'LegacyJavaScriptObject' is not a subtype of type 'DiagnosticsNode'".
//
// Approach:
// - Convert values to plain Dart strings (or native types) using `safeString`.
// - Provide `safeParseDate` and `safeDateFormatted` helpers for date fields.
// - Keep conversions defensive (try/catch) and non-intrusive so existing app
//   behavior remains unchanged.

String safeString(Object? value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();

  // Fallback: attempt a safe toString() call; if that fails, return a placeholder.
  try {
    return value.toString();
  } catch (e) {
    return '[unprintable]';
  }
}

DateTime? safeParseDate(Object? value) {
  final s = safeString(value);
  try {
    return DateTime.parse(s);
  } catch (e) {
    return null;
  }
}

String safeDateFormatted(Object? value) {
  final dt = safeParseDate(value);
  if (dt == null) return safeString(value);
  final d = dt.toLocal();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// Convert a dynamic map that may contain JS interop objects into a pure
// Dart Map<String, dynamic> where values are primitives (String/num/bool)
// or nested sanitized maps/lists. This prevents the inspector from finding
// non-Dart JS objects inside widget state.
Map<String, dynamic> sanitizeMap(Map raw) {
  final out = <String, dynamic>{};
  raw.forEach((key, value) {
    final k = key.toString();
    final v = value;
    if (v == null) {
      out[k] = null;
      return;
    }
    if (v is String || v is num || v is bool) {
      out[k] = v;
      return;
    }
    if (v is Map) {
      out[k] = sanitizeMap(v);
      return;
    }
    if (v is Iterable) {
      out[k] = v.map((e) => e is Map ? sanitizeMap(e) : safeString(e)).toList();
      return;
    }

    // Fallback: convert to string, try to coerce to number where sensible.
    final s = safeString(v);
    final i = int.tryParse(s);
    if (i != null) {
      out[k] = i;
      return;
    }
    final d = double.tryParse(s);
    if (d != null) {
      out[k] = d;
      return;
    }

    out[k] = s;
  });
  return out;
}

List<Map<String, dynamic>> sanitizeListOfMaps(List raw) {
  return raw.map((e) => e is Map ? sanitizeMap(e) : <String, dynamic>{}).cast<Map<String, dynamic>>().toList();
}
