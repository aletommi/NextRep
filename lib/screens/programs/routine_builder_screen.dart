import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/routine.dart';
import '../../providers/workout_provider.dart';
import '../../services/database_service.dart'; // Added for lookup
import 'exercise_selector_screen.dart';

class BlockItem {
  final String id;
  final String name;
  BlockItem({required this.id, required this.name});
}

class RoutineBuilderScreen extends StatefulWidget {
  final Routine? routine;

  const RoutineBuilderScreen({super.key, this.routine});

  @override
  State<RoutineBuilderScreen> createState() => _RoutineBuilderScreenState();
}

class _RoutineBuilderScreenState extends State<RoutineBuilderScreen> {
  final _nameController = TextEditingController();

  // State for Wizard
  int _currentStep = 0; // 0: Structure, 1: Fill
  final List<BlockItem> _muscleBlocks = [];

  // Data for each block: Map<BlockID, List<RoutineExercise>>
  // We use the BlockItem.id as key so data stays attached to the block even if reordered.
  final Map<String, List<RoutineExercise>> _wizardData = {};

  // For legacy/editing without structure
  List<RoutineExercise> _legacyExercises = [];

  @override
  void initState() {
    super.initState();
    if (widget.routine != null) {
      _nameController.text = widget.routine!.name;
      _legacyExercises = List.from(widget.routine!.exercises);
      // Determine blocks from existing exercises?
      // It's hard to reverse-engineer blocks from a flat list without metadata.
      // For editing existing routines, we might just skip to step 1 (Fill/Edit)
      // or treat them as a "Custom" block.
      // For simplicity, if editing, we skip structure step for now,
      // OR we can't easily support re-structuring old routines yet.
      _currentStep = 1;
    }
  }

  void _saveRoutine() {
    if (_nameController.text.isEmpty) return;
    final finalExercises = _collectAllExercises();
    if (finalExercises.isEmpty && _currentStep == 0) {
      // Allow empty structure if user didn't add anything yet? No, require at least something.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aggiungi almeno un esercizio")),
      );
      return;
    }

    final routine = Routine(
      id: widget.routine?.id ?? const Uuid().v4(),
      name: _nameController.text,
      exercises: finalExercises,
      description: "Guided Routine",
    );

    Provider.of<WorkoutProvider>(context, listen: false).addRoutine(routine);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.routine == null ? 'Nuova Scheda' : 'Modifica Scheda',
        ),
      ),
      body: Column(
        children: [
          // Step Indicator
          if (widget.routine == null)
            Row(
              children: [
                _buildStepHeader(0, "Struttura"),
                _buildStepHeader(1, "Esercizi"),
              ],
            ),
          Expanded(
            child: _currentStep == 0 ? _buildStructureStep() : _buildFillStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(int step, String title) {
    final isActive = _currentStep == step;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: isActive ? Theme.of(context).primaryColor : Colors.grey[800],
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.black : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  // --- STEP 0: STRUCTURE ---
  Widget _buildStructureStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome Scheda (es. Push Day)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Seleziona i gruppi muscolari e l'ordine:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ReorderableListView(
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = _muscleBlocks.removeAt(oldIndex);
                  _muscleBlocks.insert(newIndex, item);
                });
              },
              children: [
                for (int i = 0; i < _muscleBlocks.length; i++)
                  ListTile(
                    key: ValueKey(_muscleBlocks[i].id), // Stable ID
                    title: Text(_muscleBlocks[i].name),
                    leading: CircleAvatar(child: Text("${i + 1}")),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          // Remove data associated with this block
                          _wizardData.remove(_muscleBlocks[i].id);
                          _muscleBlocks.removeAt(i);
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
          Wrap(
            children:
                [
                      "Petto",
                      "Schiena",
                      "Gambe",
                      "Spalle",
                      "Bicipiti",
                      "Tricipiti",
                      "Addome",
                    ]
                    .map(
                      (muscle) => ActionChip(
                        label: Text(muscle),
                        onPressed: () {
                          setState(() {
                            _muscleBlocks.add(
                              BlockItem(id: const Uuid().v4(), name: muscle),
                            );
                          });
                        },
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Inserisci un nome per la scheda"),
                  ),
                );
                return;
              }
              if (_muscleBlocks.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Seleziona almeno un gruppo muscolare"),
                  ),
                );
                return;
              }
              setState(() {
                _currentStep = 1;
              });
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Avanti: Scegli Esercizi"),
          ),
        ],
      ),
    );
  }

  // --- STEP 1: FILL EXERCISES ---
  Widget _buildFillStep() {
    return Column(
      children: [
        // Helper: "Adding to: [Header]"?
        // Actually, we show the full list and allowing adding under Sections.
        // Or we iterate one by one?
        // "Show only exercises for that group" -> imply we must direct the user.

        // Let's simpler approach: Show the blocks. Each block has "Add Exercise".
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_muscleBlocks.isNotEmpty)
                ..._muscleBlocks.map(
                  (block) => _buildBlockSectionWithData(block),
                ),

              // Fallback/Legacy list (for editing old routines or extra)
              if (_muscleBlocks.isEmpty)
                ...List.generate(
                  _legacyExercises.length,
                  (index) => _buildExerciseItemWidget(
                    index,
                    _legacyExercises[index],
                    null,
                  ),
                ),

              const SizedBox(height: 24),
              // Global Add (in case they want something out of order)
              if (_muscleBlocks.isEmpty)
                ElevatedButton.icon(
                  onPressed: () => _addExercise(null),
                  icon: const Icon(Icons.add),
                  label: const Text("Aggiungi Esercizio Extra"),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              if (widget.routine == null)
                TextButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  child: const Text("Indietro"),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveRoutine,
                  icon: const Icon(Icons.save),
                  label: const Text("Salva Scheda"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Re-define state to match the "Block Map" approach
  // We need to change the state variables in the file.
  // I will assume this replace covers the whole class and I can introduce new vars.

  // But wait, `_exercises` is what I used before.
  // I will use a local mapping for the wizard, and rebuild `_exercises` on save.

  // We need to init _wizardData if editing?
  // If editing, we fall back to generic list (empty blocks).

  Widget _buildBlockSectionWithData(BlockItem block) {
    final exercises = _wizardData[block.id] ?? [];

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  block.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addExerciseToBlock(block.id, block.name),
                ),
              ],
            ),
            const Divider(),
            ...exercises.asMap().entries.map(
              (entry) =>
                  _buildExerciseItemWidget(entry.key, entry.value, block.id),
            ),
            if (exercises.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Nessun esercizio aggiunto.",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper to build the item (reused logic)
  Widget _buildExerciseItemWidget(
    int innerIndex,
    RoutineExercise routineExercise,
    String? blockId,
  ) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final exercise = db.exercisesBox.get(routineExercise.exerciseId);

    // Helper to update specific item in the specific block
    void updateExercise(RoutineExercise newEx) {
      if (blockId != null) {
        _wizardData[blockId]![innerIndex] = newEx;
      } else {
        _legacyExercises[innerIndex] = newEx;
      }
      // No setState needed during text editing if we want to avoid rebuilds,
      // but model must be updated. For simplicity, we don't setState on every char.
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise?.name ?? "Sconosciuto",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      if (blockId != null) {
                        _wizardData[blockId]!.removeAt(innerIndex);
                      } else {
                        _legacyExercises.removeAt(innerIndex);
                      }
                    });
                  },
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: routineExercise.sets,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Serie',
                      isDense: true,
                    ),
                    onChanged: (v) => updateExercise(
                      RoutineExercise(
                        exerciseId: routineExercise.exerciseId,
                        sets: v,
                        reps: routineExercise.reps,
                        weight: routineExercise.weight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: routineExercise.reps,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'Reps',
                      isDense: true,
                    ),
                    onChanged: (v) => updateExercise(
                      RoutineExercise(
                        exerciseId: routineExercise.exerciseId,
                        sets: routineExercise.sets,
                        reps: v,
                        weight: routineExercise.weight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: routineExercise.weight,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Kg',
                      isDense: true,
                    ),
                    onChanged: (v) => updateExercise(
                      RoutineExercise(
                        exerciseId: routineExercise.exerciseId,
                        sets: routineExercise.sets,
                        reps: routineExercise.reps,
                        weight: v,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Flatten data on save
  List<RoutineExercise> _collectAllExercises() {
    if (_currentStep == 0) return _legacyExercises;

    // If Wizard used, flatten following _muscleBlocks order
    if (_muscleBlocks.isNotEmpty) {
      List<RoutineExercise> flat = [];
      for (var block in _muscleBlocks) {
        if (_wizardData.containsKey(block.id)) {
          flat.addAll(_wizardData[block.id]!);
        }
      }
      return flat;
    }
    return _legacyExercises;
  }

  // Re-implement save with flatten

  Future<void> _addExercise(String? category) async {
    // Legacy method, unused
  }

  Future<void> _addExerciseToBlock(String blockId, String category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseSelectorScreen(filterCategory: category),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        if (!_wizardData.containsKey(blockId)) _wizardData[blockId] = [];
        _wizardData[blockId]!.add(
          RoutineExercise(exerciseId: result, sets: "3", reps: "10"),
        );
      });
    }
  }

  // Override build with Wizard logic
}
