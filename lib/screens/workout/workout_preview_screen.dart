import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/workout_provider.dart';
import '../../providers/workout_session_provider.dart';
import '../../models/routine.dart';
import 'live_workout_screen.dart'; // We'll create this next

class WorkoutPreviewScreen extends StatefulWidget {
  const WorkoutPreviewScreen({super.key});

  @override
  State<WorkoutPreviewScreen> createState() => _WorkoutPreviewScreenState();
}

class _WorkoutPreviewScreenState extends State<WorkoutPreviewScreen> {
  Routine? selectedRoutine;

  @override
  void initState() {
    super.initState();
    // Pre-select the next routine from logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );
      setState(() {
        selectedRoutine = workoutProvider.nextRoutine;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final routines = workoutProvider.routines;

    // Fallback if no routines
    if (routines.isEmpty) {
      return const Center(
        child: Text("Nessuna scheda attiva. Crea un programma!"),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Allenamento"),
        centerTitle: false,
        actions: [
          // Routine Dropdown
          DropdownButton<Routine>(
            value: selectedRoutine != null && routines.contains(selectedRoutine)
                ? selectedRoutine
                : routines.first,
            dropdownColor: Theme.of(context).cardColor,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down),
            items: routines.map((r) {
              return DropdownMenuItem(
                value: r,
                child: Text(
                  r.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
            onChanged: (Routine? newRoutine) {
              if (newRoutine != null) {
                setState(() {
                  selectedRoutine = newRoutine;
                });
              }
            },
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
                "Pronto a spaccare?",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),

              // Big Start Button
              GestureDetector(
                onTap: () async {
                  if (selectedRoutine == null) return;

                  final sessionProvider = Provider.of<WorkoutSessionProvider>(
                    context,
                    listen: false,
                  );
                  await sessionProvider.startSession(selectedRoutine!.name);

                  if (context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LiveWorkoutScreen(),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 300,
                  height: 300,
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_arrow_rounded,
                          size: 64,
                          color: Colors.black,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "INIZIA\n${selectedRoutine?.name.toUpperCase() ?? ''}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
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
