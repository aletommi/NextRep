import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class MuscleHeatmap extends StatelessWidget {
  const MuscleHeatmap({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Heatmap: Simple list for now as drawing a body is complex without assets
    final muscles = [
      {'name': 'Chest', 'score': 10},
      {'name': 'Back', 'score': 8},
      {'name': 'Legs', 'score': 2}, // Skipped legs day?
      {'name': 'Arms', 'score': 6},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: muscles.map((m) {
        final score = m['score'] as int;
        Color color = AppColors.muscleGroupHeatmapLow;
        if (score > 5) color = AppColors.muscleGroupHeatmapMedium;
        if (score > 8) color = AppColors.muscleGroupHeatmapHigh;

        return Chip(
          label: Text(m['name'] as String),
          backgroundColor: color,
          labelStyle: const TextStyle(color: Colors.black),
        );
      }).toList(),
    );
  }
}
