import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/database_service.dart';
import 'ghost_log.dart';
import 'rest_timer.dart';

class ExerciseFocusView extends StatefulWidget {
  final String exerciseId;

  const ExerciseFocusView({super.key, required this.exerciseId});

  @override
  State<ExerciseFocusView> createState() => _ExerciseFocusViewState();
}

class _ExerciseFocusViewState extends State<ExerciseFocusView> {
  // Mock Set Data
  // In real app, this list grows as user adds sets.
  final List<Map<String, dynamic>> _sets = [
    {'weight': 0.0, 'reps': 0, 'done': false},
    {'weight': 0.0, 'reps': 0, 'done': false},
    {'weight': 0.0, 'reps': 0, 'done': false},
  ];

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final exercise = db.exercisesBox.get(widget.exerciseId);

    if (exercise == null) {
      return const Center(child: Text("Esercizio non trovato"));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.name,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            exercise.muscleGroup,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const GhostLog(), // Suggestion from history
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _sets.length,
              itemBuilder: (context, index) {
                final set = _sets[index];
                final isDone = set['done'] as bool;

                return Card(
                  color: isDone ? Colors.green.withValues(alpha: 0.1) : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isDone ? Colors.green : Colors.grey,
                      child: Text("${index + 1}"),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(isDone ? "${set['weight']} kg" : "- kg"),
                        ),
                        Expanded(
                          child: Text(
                            isDone ? "${set['reps']} reps" : "- reps",
                          ),
                        ),
                      ],
                    ),
                    trailing: Checkbox(
                      value: isDone,
                      onChanged: (val) {
                        setState(() {
                          _sets[index]['done'] = val;
                          if (val == true) {
                            // Mock logging values (would be text fields inputs)
                            _sets[index]['weight'] = 100.0;
                            _sets[index]['reps'] = 8;

                            // Trigger Timer
                            RestTimer.show(context);
                          }
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _sets.add({'weight': 0.0, 'reps': 0, 'done': false});
                });
              },
              icon: const Icon(Icons.add),
              label: const Text("Aggiungi Serie"),
            ),
          ),
        ],
      ),
    );
  }
}
