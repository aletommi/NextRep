import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/routine.dart';
import '../../providers/program_provider.dart';
import '../../providers/workout_session_provider.dart';
import 'live_workout_screen.dart';

class WorkoutPreviewScreen extends StatefulWidget {
  const WorkoutPreviewScreen({super.key});

  @override
  State<WorkoutPreviewScreen> createState() => _WorkoutPreviewScreenState();
}

class _WorkoutPreviewScreenState extends State<WorkoutPreviewScreen> {
  /// Routine chosen by the user; null means "use the suggested one".
  String? _selectedRoutineId;

  Future<void> _start(Routine routine) async {
    if (routine.exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Questa routine non ha esercizi. Aggiungili in Schede.',
          ),
        ),
      );
      return;
    }

    final sessions = context.read<WorkoutSessionProvider>();
    await sessions.startSession(routine);

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LiveWorkoutScreen(routine: routine)),
    );
    // Whatever happened in the live screen, make sure the session is closed.
    await sessions.endSession();
    if (mounted) setState(() => _selectedRoutineId = null);
  }

  @override
  Widget build(BuildContext context) {
    final routines = context.watch<ProgramProvider>().activeRoutines;
    final sessions = context.watch<WorkoutSessionProvider>();

    if (routines.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Allenamento')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Nessuna scheda attiva.\nCreane una nella sezione Schede.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final suggested = sessions.nextRoutine(routines) ?? routines.first;
    final selected =
        routines.where((r) => r.id == _selectedRoutineId).firstOrNull ??
        suggested;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Allenamento'),
        actions: [
          DropdownButton<String>(
            value: selected.id,
            dropdownColor: Theme.of(context).cardColor,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down),
            items: routines
                .map(
                  (r) => DropdownMenuItem(
                    value: r.id,
                    child: Text(
                      r.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )
                .toList(),
            onChanged: (id) => setState(() => _selectedRoutineId = id),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Pronto a spaccare?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${selected.exercises.length} esercizi',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              GestureDetector(
                onTap: () => _start(selected),
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.play_arrow_rounded,
                            size: 64,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'INIZIA\n${selected.name.toUpperCase()}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
