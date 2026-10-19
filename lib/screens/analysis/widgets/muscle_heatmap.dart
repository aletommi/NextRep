import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/workout_session.dart';

/// Sets per muscle group in the last 30 days, colored by how much was done.
class MuscleHeatmap extends StatelessWidget {
  final List<WorkoutSession> sessions;

  const MuscleHeatmap({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final since = DateTime.now().subtract(const Duration(days: 30));
    final counts = <String, int>{};
    for (final s in sessions.where((s) => s.date.isAfter(since))) {
      for (final e in s.exercises) {
        counts[e.muscleGroup] = (counts[e.muscleGroup] ?? 0) + e.sets.length;
      }
    }

    if (counts.isEmpty) {
      return const Text(
        'Nessuna serie negli ultimi 30 giorni.',
        style: TextStyle(color: Colors.grey),
      );
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries.map((e) {
        Color color = AppColors.muscleGroupHeatmapLow;
        if (e.value >= 10) color = AppColors.muscleGroupHeatmapMedium;
        if (e.value >= 20) color = AppColors.muscleGroupHeatmapHigh;

        return Chip(
          label: Text('${e.key} · ${e.value}'),
          backgroundColor: color,
          labelStyle: const TextStyle(color: Colors.black),
        );
      }).toList(),
    );
  }
}
