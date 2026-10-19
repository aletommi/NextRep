import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_session_provider.dart';
import 'widgets/progress_chart.dart';
import 'widgets/muscle_heatmap.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<WorkoutSessionProvider>().history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisi'),
        actions: [
          IconButton(
            tooltip: 'Esci',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: history.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Completa un allenamento per vedere le tue statistiche.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Volume per allenamento',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(height: 200, child: ProgressChart(sessions: history)),
                const SizedBox(height: 32),
                const Text(
                  'Serie per gruppo muscolare (ultimi 30 giorni)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                MuscleHeatmap(sessions: history),
                const SizedBox(height: 32),
                const Text(
                  'Storico',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                for (final s in history.take(20))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.fitness_center),
                    title: Text(s.routineName),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(s.date),
                    ),
                    trailing: Text(
                      '${s.totalSets} serie\n${s.totalVolume.toStringAsFixed(0)} kg',
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
            ),
    );
  }
}
