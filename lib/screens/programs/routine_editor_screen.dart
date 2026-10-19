import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/routine.dart';
import '../../models/exercise.dart';
import '../../services/database_service.dart';
import '../../providers/program_provider.dart';

/// Edits the exercises of a routine: add, edit targets, reorder, remove.
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
  static final _defaultName = RegExp(r'^Routine [A-Z]$');

  DatabaseService get _db => context.read<DatabaseService>();

  Future<void> _save() async {
    final routine = widget.routine;

    // Routines keep their default "Routine A" name until the user renames
    // them: in that case name them after the muscle groups they contain.
    if (_defaultName.hasMatch(routine.name) && routine.exercises.isNotEmpty) {
      final groups =
          routine.exercises
              .map((rx) => _db.getExercise(rx.exerciseId)?.muscleGroup)
              .whereType<String>()
              .toSet()
              .toList()
            ..sort();
      if (groups.isNotEmpty) routine.name = groups.join(' - ');
    }

    await context.read<ProgramProvider>().saveRoutine(
      widget.programId,
      routine,
    );
    if (mounted) setState(() {});
  }

  void _addExercise() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ExercisePicker(
        onExerciseSelected: (exercise) {
          Navigator.pop(context);
          _showTargetDialog(exercise);
        },
      ),
    );
  }

  void _showTargetDialog(Exercise exercise, {int? index}) {
    final existing = index == null ? null : widget.routine.exercises[index];
    showDialog(
      context: context,
      builder: (_) => TargetDialog(
        exercise: exercise,
        initialData: existing,
        onSave: (updated) {
          if (index == null) {
            widget.routine.exercises.add(updated);
          } else {
            widget.routine.exercises[index] = updated;
          }
          _save();
        },
      ),
    );
  }

  void _removeExercise(int index) {
    widget.routine.exercises.removeAt(index);
    _save();
  }

  void _reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = widget.routine.exercises.removeAt(oldIndex);
    widget.routine.exercises.insert(newIndex, item);
    _save();
  }

  Future<void> _rename() async {
    final ctrl = TextEditingController(text: widget.routine.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rinomina routine'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    if (newName == null || newName.trim().isEmpty || !mounted) return;
    await context.read<ProgramProvider>().renameRoutine(
      widget.programId,
      widget.routine,
      newName,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final exercises = widget.routine.exercises;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routine.name),
        actions: [
          IconButton(
            tooltip: 'Rinomina',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _rename,
          ),
        ],
      ),
      body: exercises.isEmpty
          ? const Center(child: Text('Nessun esercizio. Aggiungine uno con +.'))
          : ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: exercises.length,
              onReorder: _reorder,
              itemBuilder: (context, index) {
                final item = exercises[index];
                final exercise = _db.getExercise(item.exerciseId);
                final weight = item.weight != null && item.weight!.isNotEmpty
                    ? ' @ ${item.weight} kg'
                    : '';

                return Dismissible(
                  key: ValueKey(item),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _removeExercise(index),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(exercise?.name ?? 'Esercizio sconosciuto'),
                    subtitle: Text('${item.sets} x ${item.reps}$weight'),
                    trailing: const Icon(Icons.drag_handle),
                    onTap: exercise == null
                        ? null
                        : () => _showTargetDialog(exercise, index: index),
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

/// Bottom sheet: pick a muscle group, then an exercise. Allows creating a
/// new exercise in the chosen group.
class ExercisePicker extends StatefulWidget {
  final ValueChanged<Exercise> onExerciseSelected;
  const ExercisePicker({super.key, required this.onExerciseSelected});

  @override
  State<ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<ExercisePicker> {
  String? _selectedMuscle;

  Future<void> _createExercise(DatabaseService db, String muscle) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nuovo esercizio · $muscle'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Crea'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;

    final exercise = Exercise(
      id: const Uuid().v4(),
      name: name.trim(),
      muscleGroup: muscle,
    );
    await db.addExercise(exercise);
    widget.onExerciseSelected(exercise);
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    final allExercises = db.getAllExercises();

    final muscles = {
      ...DatabaseService.muscleGroups,
      ...allExercises.map((e) => e.muscleGroup),
    }.toList();

    final selected = _selectedMuscle;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Seleziona esercizio',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            if (selected == null) ...[
              const Text('Scegli gruppo muscolare'),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2,
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
                  Expanded(
                    child: Text(
                      selected,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _createExercise(db, selected),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuovo'),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  children: allExercises
                      .where((e) => e.muscleGroup == selected)
                      .map(
                        (e) => ListTile(
                          title: Text(e.name),
                          onTap: () => widget.onExerciseSelected(e),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dialog to set sets / reps / weight / rest for an exercise in a routine.
/// "Carico costante" uses one value for all sets, "Serie modulari" one value
/// per set (stored comma-separated, e.g. "10,8,6").
class TargetDialog extends StatefulWidget {
  final Exercise exercise;
  final RoutineExercise? initialData;
  final ValueChanged<RoutineExercise> onSave;

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
  final _restCtrl = TextEditingController(text: '90');
  final _notesCtrl = TextEditingController();

  bool _isModular = false;
  int _setsCount = 3;

  // Constant mode
  final _setsCtrl = TextEditingController(text: '3');
  final _repsCtrl = TextEditingController(text: '10');
  final _weightCtrl = TextEditingController();

  // Modular mode: one (reps, weight) pair per set
  final List<({TextEditingController reps, TextEditingController weight})>
  _rows = [];

  @override
  void initState() {
    super.initState();
    final ex = widget.initialData;
    if (ex == null) return;

    _restCtrl.text = ex.restTimeSeconds?.toString() ?? '90';
    _notesCtrl.text = ex.notes ?? '';
    _setsCount = int.tryParse(ex.sets) ?? 3;
    _isModular = ex.reps.contains(',') || (ex.weight?.contains(',') ?? false);

    if (_isModular) {
      final reps = ex.reps.split(',');
      final weights = (ex.weight ?? '').split(',');
      for (var i = 0; i < _setsCount; i++) {
        _rows.add((
          reps: TextEditingController(
            text: (i < reps.length ? reps[i] : reps.last).trim(),
          ),
          weight: TextEditingController(
            text: (i < weights.length ? weights[i] : weights.last).trim(),
          ),
        ));
      }
    } else {
      _setsCtrl.text = ex.sets;
      _repsCtrl.text = ex.reps;
      _weightCtrl.text = ex.weight ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in [
      _restCtrl,
      _notesCtrl,
      _setsCtrl,
      _repsCtrl,
      _weightCtrl,
    ]) {
      c.dispose();
    }
    for (final r in _rows) {
      r.reps.dispose();
      r.weight.dispose();
    }
    super.dispose();
  }

  void _toggleMode(bool? value) {
    if (value == null) return;
    setState(() {
      _isModular = value;
      if (_isModular) {
        _setsCount = (int.tryParse(_setsCtrl.text) ?? 3).clamp(1, 20);
        _rows.clear();
        for (var i = 0; i < _setsCount; i++) {
          _rows.add((
            reps: TextEditingController(text: _repsCtrl.text),
            weight: TextEditingController(text: _weightCtrl.text),
          ));
        }
      } else if (_rows.isNotEmpty) {
        _setsCtrl.text = _setsCount.toString();
        _repsCtrl.text = _rows.first.reps.text;
        _weightCtrl.text = _rows.first.weight.text;
      }
    });
  }

  void _onSave() {
    String sets;
    String reps;
    String? weight;

    if (!_isModular) {
      if (_setsCtrl.text.trim().isEmpty || _repsCtrl.text.trim().isEmpty) {
        return;
      }
      sets = _setsCtrl.text.trim();
      reps = _repsCtrl.text.trim();
      weight = _weightCtrl.text.trim().isEmpty ? null : _weightCtrl.text.trim();
    } else {
      sets = _setsCount.toString();
      reps = _rows.map((r) => r.reps.text.trim()).join(',');
      final weights = _rows.map((r) => r.weight.text.trim());
      weight = weights.every((w) => w.isEmpty) ? null : weights.join(',');
    }

    widget.onSave(
      RoutineExercise(
        exerciseId: widget.exercise.id,
        sets: sets,
        reps: reps,
        weight: weight,
        restTimeSeconds: int.tryParse(_restCtrl.text) ?? 90,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.exercise.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Modalità: ',
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
                        'Carico Costante',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: true,
                      child: Text(
                        'Serie Modulari',
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
                labelText: 'Recupero (secondi)',
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Note',
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
          child: const Text('Annulla'),
        ),
        ElevatedButton(onPressed: _onSave, child: const Text('Salva')),
      ],
    );
  }

  Widget _buildConstantForm() {
    return Column(
      children: [
        TextField(
          controller: _setsCtrl,
          decoration: const InputDecoration(
            labelText: 'Serie',
            hintText: 'es. 4',
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _repsCtrl,
          decoration: const InputDecoration(
            labelText: 'Reps',
            hintText: 'es. 8-10',
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ),
        TextField(
          controller: _weightCtrl,
          decoration: const InputDecoration(
            labelText: 'Carico (kg) - opzionale',
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }

  Widget _buildModularForm() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Numero di serie: '),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _setsCount > 1
                      ? () => setState(() {
                          _setsCount--;
                          final removed = _rows.removeLast();
                          removed.reps.dispose();
                          removed.weight.dispose();
                        })
                      : null,
                ),
                Text(
                  '$_setsCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _setsCount < 20
                      ? () => setState(() {
                          _setsCount++;
                          final last = _rows.lastOrNull;
                          _rows.add((
                            reps: TextEditingController(
                              text: last?.reps.text ?? '',
                            ),
                            weight: TextEditingController(
                              text: last?.weight.text ?? '',
                            ),
                          ));
                        })
                      : null,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(_rows.length, (index) {
          final row = _rows[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                SizedBox(
                  width: 25,
                  child: Text(
                    '${index + 1}°',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: row.reps,
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
                    controller: row.weight,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
}
