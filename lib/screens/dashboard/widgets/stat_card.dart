import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class StatCard extends StatelessWidget {
  final String message;

  const StatCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.trending_up, color: AppColors.secondary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
