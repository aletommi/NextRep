import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/program_provider.dart';
import '../../providers/workout_session_provider.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onGoToWorkout;

  const DashboardScreen({super.key, required this.onGoToWorkout});

  @override
  Widget build(BuildContext context) {
    final programs = context.watch<ProgramProvider>();
    final sessions = context.watch<WorkoutSessionProvider>();

    final next = sessions.nextRoutine(programs.activeRoutines);
    final last = sessions.lastWorkout;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            next == null ? 'Nessuna scheda attiva' : 'Prossimo allenamento',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            color: Theme.of(context).primaryColor,
            child: InkWell(
              onTap: onGoToWorkout,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        next?.name.toUpperCase() ?? 'CREA UNA SCHEDA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.white),
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
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Allenamenti',
                  value: '${sessions.totalWorkouts}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Questa settimana',
                  value: '${sessions.workoutsThisWeek}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (last == null)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Completa il tuo primo allenamento per vedere le statistiche!',
              ),
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text('Ultimo: ${last.routineName}'),
                subtitle: Text(
                  '${DateFormat('dd/MM/yyyy').format(last.date)} · '
                  '${last.totalSets} serie · '
                  '${last.totalVolume.toStringAsFixed(0)} kg totali',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
