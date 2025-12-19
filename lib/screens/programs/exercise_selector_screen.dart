import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/exercise.dart';
import '../../services/database_service.dart';

class ExerciseSelectorScreen extends StatefulWidget {
  final String?
  filterCategory; // Optional: If set, only show exercises in this category

  const ExerciseSelectorScreen({super.key, this.filterCategory});

  @override
  State<ExerciseSelectorScreen> createState() => _ExerciseSelectorScreenState();
}

class _ExerciseSelectorScreenState extends State<ExerciseSelectorScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  List<dynamic> _groupedExercises(List<Exercise> exercises) {
    if (exercises.isEmpty) return [];

    // Sort by muscle group first
    exercises.sort((a, b) => a.muscleGroup.compareTo(b.muscleGroup));

    final Map<String, List<Exercise>> groups = {};
    for (var ex in exercises) {
      if (!groups.containsKey(ex.muscleGroup)) {
        groups[ex.muscleGroup] = [];
      }
      groups[ex.muscleGroup]!.add(ex);
    }

    final List<dynamic> result = [];
    groups.forEach((key, value) {
      result.add(key); // Header
      result.addAll(value);
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    // We need access to exercises. DatabaseService has them specifically.
    // Ideally WorkoutProvider exposes them.
    // For now using DatabaseService directly or via Provider.

    final dbService = Provider.of<DatabaseService>(context);
    // This is not reactive if we don't use Listenable, but for now OK.
    List<Exercise> allExercises = dbService.getAllExercises();

    // Filter
    final filtered = allExercises.where((e) {
      final matchesSearch = e.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesCategory =
          widget.filterCategory == null ||
          e.muscleGroup == widget.filterCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.filterCategory != null
              ? 'Esercizi ${widget.filterCategory}'
              : 'Seleziona Esercizio',
        ),
      ),
      body: Column(
        children: [
          if (widget.filterCategory == null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Cerca...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _groupedExercises(filtered).length,
              itemBuilder: (context, index) {
                final item = _groupedExercises(filtered)[index];
                if (item is String) {
                  // Header
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    color: Colors.grey[800],
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  );
                } else if (item is Exercise) {
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text(item.muscleGroup),
                    onTap: () {
                      Navigator.pop(context, item.id);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateExerciseDialog(context, dbService),
        tooltip: 'Crea Nuovo Esercizio',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateExerciseDialog(BuildContext context, DatabaseService db) {
    final nameCtrl = TextEditingController();
    final muscleCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nuovo Esercizio"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Nome"),
            ),
            TextField(
              controller: muscleCtrl,
              decoration: const InputDecoration(labelText: "Gruppo Muscolare"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annulla"),
          ),
          TextButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && muscleCtrl.text.isNotEmpty) {
                final newEx = Exercise(
                  id: const Uuid().v4(),
                  name: nameCtrl.text,
                  muscleGroup: muscleCtrl.text,
                );
                await db.addExercise(newEx);
                if (ctx.mounted) {
                  // Only if we want to force rebuild of parent if needed, setState here might be useless if dialog is poped
                  // But we called setState on parent before pop? No, setState on THIS widget (Dialog?)
                  // The dialog is being built by showDialog builder.
                  // Wait, the setState call in original code was: setState(() {});
                  // This setState refers to _ExerciseSelectorScreenState because it's a closure inside the method of the State class!
                  // Correct.
                  setState(() {});
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text("Salva"),
          ),
        ],
      ),
    );
  }
}
