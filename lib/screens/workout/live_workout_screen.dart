import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/workout_session_provider.dart';
import '../../providers/workout_provider.dart';
import '../../services/database_service.dart';
import '../../models/routine.dart';
import 'widgets/workout_keypad.dart';
import 'recap_screen.dart';

class LiveWorkoutScreen extends StatefulWidget {
  final int initialIndex;
  const LiveWorkoutScreen({super.key, this.initialIndex = 0});

  @override
  State<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends State<LiveWorkoutScreen> {
  int _currentExerciseIndex = 0;
  Routine? _activeRoutine;

  // Weight Confirmation State
  bool _showWeightConfirmation = false;
  Timer? _confirmationTimer; // The 15s auto-confirm timer
  Timer? _restTicker; // Ticker to update UI during rest
  int _confirmationCountdown = 15;
  double _pendingWeight = 0.0;

  @override
  void initState() {
    super.initState();
    _currentExerciseIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initRoutine();
    });
  }

  void _initRoutine() {
    final sessionProvider = Provider.of<WorkoutSessionProvider>(
      context,
      listen: false,
    );
    final workoutProvider = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    );

    final session = sessionProvider.activeSession;
    if (session == null) {
      Navigator.pop(context); // Safety
      return;
    }

    try {
      _activeRoutine = workoutProvider.routines.firstWhere(
        (r) => r.name == session.routineName,
      );
    } catch (_) {
      // Routine not found?
      // Should handle this, but for now assume it exists or fallback.
    }

    if (_activeRoutine != null && _activeRoutine!.exercises.isNotEmpty) {
      _setExercise(_currentExerciseIndex);
    }
  }

  // Helper to get name
  String _getExerciseName(RoutineExercise routineEx) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final ex = db.exercisesBox.get(routineEx.exerciseId);
    return ex?.name ?? "Esercizio";
  }

  void _setExercise(int index) {
    if (_activeRoutine == null) return;

    final routineEx = _activeRoutine!.exercises[index];
    final exerciseName = _getExerciseName(routineEx);

    final sessionProvider = Provider.of<WorkoutSessionProvider>(
      context,
      listen: false,
    );

    // We pass "Unknown" for muscleGroup for now as it's not critical for logic,
    // but ideally we'd look it up from DB too.
    sessionProvider.setActiveExercise(exerciseName, "Unknown");

    setState(() {
      _currentExerciseIndex = index;
    });
  }

  // Parses comma-separated values (e.g. "10,8,6") and returns the one for the current set index.
  // Falls back to the last value if index exceeds list, or the original string if no commas.
  String _getTargetValue(String? source, int setIndex) {
    if (source == null || source.isEmpty) return "0";
    if (!source.contains(',')) return source;

    final parts = source.split(',').map((e) => e.trim()).toList();
    if (parts.isEmpty) return "0";

    if (setIndex < parts.length) {
      return parts[setIndex];
    }
    return parts.last; // Fallback to last specified target
  }

  // --- Logic Flow ---

  void _onRepSelected(int reps) async {
    final sessionProvider = Provider.of<WorkoutSessionProvider>(
      context,
      listen: false,
    );
    final currentRoutineEx = _activeRoutine!.exercises[_currentExerciseIndex];
    final targetSets = int.tryParse(currentRoutineEx.sets) ?? 3;

    final currentSetIndex = sessionProvider.activeExercise?.sets.length ?? 0;

    // Get suggestion
    double suggestedWeight;
    final targetWeightStr = _getTargetValue(
      currentRoutineEx.weight,
      currentSetIndex,
    );

    if (targetWeightStr != '0' && targetWeightStr.isNotEmpty) {
      suggestedWeight = double.tryParse(targetWeightStr) ?? 50.0;
    } else {
      suggestedWeight =
          await sessionProvider.getSuggestedWeight(
            sessionProvider.activeExercise?.exerciseName ?? "",
            currentSetIndex,
          ) ??
          50.0;
    }

    _pendingWeight = suggestedWeight;

    // Add Set
    await sessionProvider.addSet(reps, suggestedWeight);

    // Check if LAST set
    final completedSets = (sessionProvider.activeExercise?.sets.length ?? 0);

    if (completedSets >= targetSets) {
      // Navigate to Recap
      if (mounted) {
        // Start Timer visually in background or overlay?
        // Prompt says: "Start timer... Instead of input screen, show Recap".
        sessionProvider.startRestTimer(); // Ensure timer starts in background

        // Fetch comparison stats
        final stats = await sessionProvider.getExerciseStats(
          _getExerciseName(currentRoutineEx),
        );

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RecapScreen(
              exerciseName: _getExerciseName(currentRoutineEx),
              stats: stats,
              restSeconds: currentRoutineEx.restTimeSeconds ?? 90,
              onNext: (ctx) {
                if (_currentExerciseIndex + 1 <
                    _activeRoutine!.exercises.length) {
                  Navigator.of(ctx).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => LiveWorkoutScreen(
                        initialIndex: _currentExerciseIndex + 1,
                      ),
                    ),
                  );
                } else {
                  Navigator.of(ctx).pop(); // Exit to Home
                }
              },
            ),
          ),
        );
      }
    } else {
      // Normal confirmation flow + Rest Timer UI
      _startConfirmationFlow();
      _startRestTicker();
    }
  }

  void _startRestTicker() {
    _restTicker?.cancel();
    _restTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  void _startConfirmationFlow() {
    setState(() {
      _showWeightConfirmation = true;
      _confirmationCountdown = 15;
    });

    // Start countdown for auto-confirm
    _confirmationTimer?.cancel();
    _confirmationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_confirmationCountdown > 0) {
        setState(() {
          _confirmationCountdown--;
        });
      } else {
        _autoConfirm();
      }
    });
  }

  void _autoConfirm() {
    _confirmationTimer?.cancel();
    setState(() {
      _showWeightConfirmation = false;
    });
  }

  void _manualConfirm() {
    _confirmationTimer?.cancel();
    setState(() {
      _showWeightConfirmation = false;
    });
  }

  void _changeWeight() async {
    _confirmationTimer?.cancel();

    double? newWeight = await showDialog<double>(
      context: context,
      builder: (_) => _WeightInputDialog(initialValue: _pendingWeight),
    );

    if (newWeight != null && newWeight != _pendingWeight) {
      // TODO: Update set weight in provider
    }

    setState(() {
      _showWeightConfirmation = false;
    });
  }

  @override
  void dispose() {
    _confirmationTimer?.cancel();
    _restTicker?.cancel(); // Cancel rest ticker
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_activeRoutine == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Logic to resume from correct exercise if we just reloaded?
    // See `_initRoutine` comment. Ideally implemented there.

    final currentEx = _activeRoutine!.exercises[_currentExerciseIndex];
    final nextEx =
        (_currentExerciseIndex + 1 < _activeRoutine!.exercises.length)
        ? _activeRoutine!.exercises[_currentExerciseIndex + 1]
        : null;

    final sessionProvider = Provider.of<WorkoutSessionProvider>(context);
    final isResting = sessionProvider.isTimerRunning;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 48), // Spacer for balance
                          Text(
                            "GRUPPO MUSCOLARE",
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: _finishWorkout,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getExerciseName(currentEx),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      // Target
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Builder(
                          builder: (context) {
                            final currentSetIndex =
                                sessionProvider.activeExercise?.sets.length ??
                                0;
                            final targetReps = _getTargetValue(
                              currentEx.reps,
                              currentSetIndex,
                            );
                            final targetWeight = _getTargetValue(
                              currentEx.weight,
                              currentSetIndex,
                            );

                            final weightText =
                                (targetWeight != '0' && targetWeight.isNotEmpty)
                                ? ' | ${targetWeight}kg'
                                : '';

                            return Text(
                              "Serie ${currentSetIndex + 1} di ${currentEx.sets} | Target: $targetReps reps$weightText",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                if (nextEx != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "Next: ${_getExerciseName(nextEx)}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                const Spacer(),

                if (_showWeightConfirmation)
                  const SizedBox.shrink()
                else
                  Column(
                    children: [
                      const Text(
                        "Ripetizioni fatte?",
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: WorkoutKeypad(onRepSelected: _onRepSelected),
                      ),
                    ],
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),

          // OVERLAY
          if (isResting || _showWeightConfirmation)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(
                  alpha: 0.95,
                ), // High opacity for focus
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "RECUPERO",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    // Timer
                    Text(
                      "${DateTime.now().difference(sessionProvider.restStartTime ?? DateTime.now()).inSeconds}s",
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 32),

                    if (_showWeightConfirmation) ...[
                      // Weight Popup Content
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LinearProgressIndicator(
                              value: _confirmationCountdown / 15.0,
                              backgroundColor: Colors.grey[800],
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Carico usato: ${_pendingWeight}kg?",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: _changeWeight,
                                    child: const Text("Cambia"),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _manualConfirm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    child: const Text("CONFERMA"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ElevatedButton(
                        onPressed: () {
                          final sessionProvider =
                              Provider.of<WorkoutSessionProvider>(
                                context,
                                listen: false,
                              );
                          sessionProvider.stopRestTimer();
                          _restTicker?.cancel();
                        },
                        child: const Text("TORNA ALLA SERIE"),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _skipRest,
                        child: const Text(
                          "SALTA RECUPERO",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _skipRest() {
    final sessionProvider = Provider.of<WorkoutSessionProvider>(
      context,
      listen: false,
    );
    sessionProvider.stopRestTimer();
    _restTicker?.cancel();
  }

  Future<void> _finishWorkout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Terminare Allenamento?"),
        content: const Text("Sei sicuro di voler chiudere la sessione?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annulla"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Termina"),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop(); // Back to Home
    }
  }
}

class _WeightInputDialog extends StatefulWidget {
  final double initialValue;
  const _WeightInputDialog({required this.initialValue});

  @override
  State<_WeightInputDialog> createState() => _WeightInputDialogState();
}

class _WeightInputDialogState extends State<_WeightInputDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.toString());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Modifica Peso"),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annulla"),
        ),
        TextButton(
          onPressed: () {
            final val = double.tryParse(_controller.text);
            Navigator.pop(context, val);
          },
          child: const Text("OK"),
        ),
      ],
    );
  }
}
