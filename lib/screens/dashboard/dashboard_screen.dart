import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/workout_provider.dart';
import 'widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onGoToWorkout;

  const DashboardScreen({super.key, required this.onGoToWorkout});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorkoutProvider>(context);
    final feed = provider.smartFeed;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Pronto per allenarti?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            color: Theme.of(context).primaryColor,
            child: InkWell(
              onTap: onGoToWorkout,
              child: const Padding(
                padding: EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fitness_center, color: Colors.white, size: 32),
                    SizedBox(width: 16),
                    Text(
                      "VAI ALL'ALLENAMENTO",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
          const Text(
            'I tuoi progressi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (feed.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Completa il tuo primo allenamento per vedere le statistiche!",
              ),
            )
          else
            ...feed.map(
              (msg) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: StatCard(message: msg),
              ),
            ),
        ],
      ),
    );
  }
}
