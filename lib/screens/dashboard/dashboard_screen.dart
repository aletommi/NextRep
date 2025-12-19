import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/workout_provider.dart';
import '../../core/constants/strings.dart';
import 'widgets/next_session_card.dart';
import 'widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorkoutProvider>(context);
    final nextRoutine = provider.nextRoutine;
    final feed = provider.smartFeed;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            AppStrings.nextUp,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (nextRoutine != null)
            NextSessionCard(routine: nextRoutine)
          else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Crea la tua prima scheda per iniziare!"),
              ),
            ),

          const SizedBox(height: 24),
          const Text(
            'I tuoi progressi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
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
