import 'package:flutter/material.dart';
import '../../../models/routine.dart';
import '../../../core/constants/colors.dart';
import '../../workout/workout_screen.dart';

class NextSessionCard extends StatelessWidget {
  final Routine routine;

  const NextSessionCard({super.key, required this.routine});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WorkoutScreen(routine: routine)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "OGGI TOCCA A",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                routine.name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${routine.exercises.length} Esercizi", // Placeholder for actual muscle group logic
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
