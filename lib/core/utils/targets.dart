// Helpers for routine targets stored as strings.
//
// Reps and weight in a routine can be a single value ("10") or a
// comma-separated list with one entry per set ("10,8,6").

/// Returns the target for [setIndex] (0-based). Falls back to the last
/// entry when the index exceeds the list, and to "" when there is no value.
String targetForSet(String? source, int setIndex) {
  if (source == null || source.trim().isEmpty) return '';
  final parts = source.split(',').map((e) => e.trim()).toList();
  if (setIndex < parts.length) return parts[setIndex];
  return parts.last;
}

/// Parses a weight string like "60" or "60.5"; returns null if empty/invalid
/// or zero.
double? parseWeight(String? source) {
  if (source == null) return null;
  final value = double.tryParse(source.trim().replaceAll(',', '.'));
  if (value == null || value <= 0) return null;
  return value;
}

/// Parses a reps string like "8" or "8-10" (takes the first number).
int? parseReps(String? source) {
  if (source == null) return null;
  final match = RegExp(r'\d+').firstMatch(source);
  if (match == null) return null;
  return int.tryParse(match.group(0)!);
}

/// Total target volume (reps x weight summed over the sets) for a routine
/// exercise. Returns 0 when weight targets are missing.
double targetVolume({
  required String sets,
  required String reps,
  required String? weight,
}) {
  final setsCount = int.tryParse(sets.trim()) ?? 0;
  var total = 0.0;
  for (var i = 0; i < setsCount; i++) {
    final r = parseReps(targetForSet(reps, i)) ?? 0;
    final w = parseWeight(targetForSet(weight, i)) ?? 0;
    total += r * w;
  }
  return total;
}
