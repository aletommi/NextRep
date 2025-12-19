import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/routine.dart';
import '../../models/exercise.dart';
import '../../services/database_service.dart';
import '../../providers/program_provider.dart';

class RoutineEditorScreen extends StatefulWidget {
  final String programId;
  final Routine routine;

  const RoutineEditorScreen({
    super.key,
    required this.programId,
    required this.routine,
  });

  @override
  State<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends State<RoutineEditorScreen> {
  // We need to keep track of exercises.
  // We should modify the Routine object directly or a local copy?
  // We'll modify the object and call save on Provider.

  void _addExercise() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ExercisePicker(
        onExerciseSelected: (exercise) {
          Navigator.pop(context); // Close picker
          _showTargetDialog(exercise);
        },
      ),
    );
  }

  void _showTargetDialog(Exercise exercise, {RoutineExercise? existing}) {
    showDialog(
      context: context,
      builder: (_) => TargetDialog(
        exercise: exercise,
        initialData: existing,
        onSave: (sets, reps, weight, rest, notes) {
          setState(() {
            if (existing != null) {
              // Update flow not fully implemented in this MVP snippet,
              // ideally we find index and replace.
              // But for "Add", we are creating new.
            } else {
              final newRoutineExercise = RoutineExercise(
                exerciseId: exercise.id,
                sets: sets,
                reps: reps,
                weight: weight,
                restTimeSeconds: rest,
                notes: notes,
              );
              widget.routine.exercises.add(newRoutineExercise);
            }
          });
          _saveRoutine();
        },
      ),
    );
  }

  void _saveRoutine() {
    Provider.of<ProgramProvider>(
      context,
      listen: false,
    ).updateRoutine(widget.programId, widget.routine);
  }

  void _removeExercise(int index) {
    setState(() {
      widget.routine.exercises.removeAt(index);
    });
    _saveRoutine();
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = widget.routine.exercises.removeAt(oldIndex);
      widget.routine.exercises.insert(newIndex, item);
    });
    _saveRoutine();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.routine.name)),
      body: ReorderableListView.builder(
        itemCount: widget.routine.exercises.length,
        onReorder: _reorder,
        itemBuilder: (context, index) {
          final item = widget.routine.exercises[index];
          // We need to fetch Exercise Name not just ID.
          // Ideally RoutineExercise should store name or we lookup.
          // For now let's do a future builder or lookup if we have the list.
          // A helper widget is best.

          return Dismissible(
            key: ValueKey(
              item,
            ), // RoutineExercise extends HiveObject, has key? No, item is object.
            // Wait, HiveObject has key, but if it's not saved to box yet?
            // uniqueKey() is better if objects are transient.
            // Logic check: RoutineExercise extends HiveObject.
            background: Container(color: Colors.red),
            onDismissed: (_) => _removeExercise(index),
            child: ListTile(
              key: ValueKey(item),
              title: ExerciseNameView(exerciseId: item.exerciseId),
              subtitle: Text(
                "${item.sets} x ${item.reps} ${item.weight != null ? '@ ${item.weight}kg' : ''}",
              ),
              trailing: const Icon(Icons.drag_handle),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExercise,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Helper Widgets (Mocking them inline or separate files? Inline for speed now)

class ExerciseNameView extends StatelessWidget {
  final String exerciseId;
  const ExerciseNameView({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(
      context,
      listen: false,
    ); // Listed false? Or true if names change?
    // Hive boxes are sync.
    final exercise = db.exercisesBox.get(exerciseId);
    return Text(exercise?.name ?? "Unknown Exercise");
  }
}

class ExercisePicker extends StatefulWidget {
  final Function(Exercise) onExerciseSelected;
  const ExercisePicker({super.key, required this.onExerciseSelected});

  @override
  State<ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<ExercisePicker> {
  String? _selectedMuscle;

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final allExercises = db.getAllExercises();

    // Get unique muscles
    final muscles = allExercises.map((e) => e.muscleGroup).toSet().toList();
    muscles.sort();

    return Container(
      height: 600,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            "Seleziona Esercizio",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          if (_selectedMuscle == null) ...[
            Text("Scegli Gruppo Muscolare"),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: muscles.length,
                itemBuilder: (context, index) {
                  final muscle = muscles[index];
                  return InkWell(
                    onTap: () => setState(() => _selectedMuscle = muscle),
                    child: Card(
                      color: Colors.blueGrey.shade800,
                      child: Center(
                        child: Text(
                          muscle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _selectedMuscle = null),
                  icon: const Icon(Icons.arrow_back),
                ),
                Text(
                  _selectedMuscle!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            Expanded(
              child: ListView(
                children: allExercises
                    .where((e) => e.muscleGroup == _selectedMuscle)
                    .map((e) {
                      return ListTile(
                        title: Text(e.name),
                        onTap: () => widget.onExerciseSelected(e),
                      );
                    })
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TargetDialog extends StatefulWidget {
  final Exercise exercise;
  final RoutineExercise? initialData;
  final Function(
    String sets,
    String reps,
    String? weight,
    int? rest,
    String? notes,
  )
  onSave;

  const TargetDialog({
    super.key,
    required this.exercise,
    this.initialData,
    required this.onSave,
  });

  @override
  State<TargetDialog> createState() => _TargetDialogState();
}

class _TargetDialogState extends State<TargetDialog> {
  // Common for both modes
  final _restCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Mode Toggle
  bool _isModular = false;
  int _setsCount = 3;

  // Constant Mode Controllers
  final _setsCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  // Modular Mode Controllers
  final List<Map<String, TextEditingController>> _modularCtrls = [];

  @override
  void initState() {
    super.initState();
    _initValues();
  }

  void _initValues() {
    // Defaults
    _restCtrl.text = "90";

    if (widget.initialData != null) {
      _restCtrl.text = widget.initialData!.restTimeSeconds?.toString() ?? "90";
      _notesCtrl.text = widget.initialData!.notes ?? "";

      final ex = widget.initialData!;
      final hasComma =
          (ex.reps.contains(',') || (ex.weight?.contains(',') ?? false));
      _isModular = hasComma;
      _setsCount = int.tryParse(ex.sets) ?? 3;

      if (!_isModular) {
        _setsCtrl.text = ex.sets;
        _repsCtrl.text = ex.reps;
        _weightCtrl.text = ex.weight ?? "";
      } else {
        _initModularControllers(ex.reps, ex.weight);
      }
    } else {
      // New exercise default
      _setsCount = 3;
    }
  }

  void _initModularControllers(String repsStr, String? weightStr) {
    _modularCtrls.clear();
    final repsParts = repsStr.split(',');
    final weightParts = (weightStr ?? "").split(',');

    for (int i = 0; i < _setsCount; i++) {
      String r = "";
      String w = "";
      if (i < repsParts.length) {
        r = repsParts[i].trim();
      } else if (repsParts.isNotEmpty) {
        r = repsParts.last.trim(); // fallback
      }

      if (i < weightParts.length) {
        w = weightParts[i].trim();
      } else if (weightParts.isNotEmpty) {
        w = weightParts.last.trim();
      }

      _modularCtrls.add({
        'reps': TextEditingController(text: r),
        'weight': TextEditingController(text: w),
      });
    }
  }

  void _toggleMode(bool? value) {
    if (value == null) return;
    setState(() {
      _isModular = value;
      if (_isModular) {
        // Switch Constant -> Modular
        _setsCount = int.tryParse(_setsCtrl.text) ?? 3;
        _modularCtrls.clear();
        for (int i = 0; i < _setsCount; i++) {
          _modularCtrls.add({
            'reps': TextEditingController(text: _repsCtrl.text),
            'weight': TextEditingController(text: _weightCtrl.text),
          });
        }
      } else {
        // Switch Modular -> Constant
        if (_modularCtrls.isNotEmpty) {
          _setsCtrl.text = _setsCount.toString();
          _repsCtrl.text = _modularCtrls[0]['reps']?.text ?? "";
          _weightCtrl.text = _modularCtrls[0]['weight']?.text ?? "";
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.exercise.name),
      content: SingleChildScrollView(
        child: Column(
          children: [
            // Mode Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Modalità: ",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                DropdownButton<bool>(
                  value: _isModular,
                  isDense: true,
                  underline: Container(),
                  items: const [
                    DropdownMenuItem(
                      value: false,
                      child: Text(
                        "Carico Costante",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: true,
                      child: Text(
                        "Serie Modulari",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  onChanged: _toggleMode,
                ),
              ],
            ),
            const Divider(),

            if (!_isModular) _buildConstantForm() else _buildModularForm(),

            const SizedBox(height: 16),
            TextField(
              controller: _restCtrl,
              decoration: const InputDecoration(
                labelText: "Recupero (secondi)",
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: "Note",
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annulla"),
        ),
        ElevatedButton(onPressed: _onSave, child: const Text("Salva")),
      ],
    );
  }

  Widget _buildConstantForm() {
    return Column(
      children: [
        TextField(
          controller: _setsCtrl,
          decoration: const InputDecoration(
            labelText: "Sets",
            hintText: "es. 4",
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _repsCtrl,
          decoration: const InputDecoration(
            labelText: "Reps",
            hintText: "es. 8-10",
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          keyboardType: TextInputType.text,
        ),
        TextField(
          controller: _weightCtrl,
          decoration: const InputDecoration(
            labelText: "Carico (Kg) - Opzionale",
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildModularForm() {
    return Column(
      children: [
        // Set Count Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Numero di Serie: "),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    if (_setsCount > 1) {
                      setState(() {
                        _setsCount--;
                        _modularCtrls.removeLast();
                      });
                    }
                  },
                ),
                Text(
                  "$_setsCount",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    if (_setsCount < 20) {
                      setState(() {
                        _setsCount++;
                        // Add new row by copying the last one logic
                        String lastReps = "";
                        String lastWeight = "";
                        if (_modularCtrls.isNotEmpty) {
                          lastReps = _modularCtrls.last['reps']?.text ?? "";
                          lastWeight = _modularCtrls.last['weight']?.text ?? "";
                        }
                        _modularCtrls.add({
                          'reps': TextEditingController(text: lastReps),
                          'weight': TextEditingController(text: lastWeight),
                        });
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Rows
        // Limit height or scrollable? Parent is SingleChildScrollView.
        ...List.generate(_setsCount, (index) {
          final ctrlMap = _modularCtrls[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                SizedBox(
                  width: 25,
                  child: Text(
                    "${index + 1}°",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: ctrlMap['reps'],
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'Reps',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: ctrlMap['weight'],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Kg',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _onSave() {
    String finalSets;
    String finalReps;
    String? finalWeight;

    if (!_isModular) {
      if (_setsCtrl.text.isEmpty || _repsCtrl.text.isEmpty) {
        return; // Basic validation
      }
      finalSets = _setsCtrl.text;
      finalReps = _repsCtrl.text;
      finalWeight = _weightCtrl.text.isEmpty ? null : _weightCtrl.text;
    } else {
      finalSets = _setsCount.toString();
      finalReps = _modularCtrls
          .map((m) => m['reps']?.text.trim() ?? "0")
          .join(',');
      finalWeight = _modularCtrls
          .map((m) => m['weight']?.text.trim() ?? "0")
          .join(',');
    }

    widget.onSave(
      finalSets,
      finalReps,
      finalWeight,
      int.tryParse(_restCtrl.text) ?? 90,
      _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
    );
    Navigator.pop(context);
  }
}
