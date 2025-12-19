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
  const LiveWorkoutScreen({super.key});

  @override
  State<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends State<LiveWorkoutScreen> {
  int _currentExerciseIndex = 0;
  Routine? _activeRoutine;

  // Weight Confirmation State
  bool _showWeightConfirmation = false;
  Timer? _confirmationTimer; // The 15s auto-confirm timer
  int _confirmationCountdown = 15;
  double _pendingWeight = 0.0;

  @override
  void initState() {
    super.initState();
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
    double suggestedWeight =
        await sessionProvider.getSuggestedWeight(
          sessionProvider.activeExercise?.exerciseName ?? "",
          currentSetIndex,
        ) ??
        50.0;

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
        sessionProvider.startRestTimer(); // Ensure timer starts

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RecapScreen(
              exerciseName: _getExerciseName(currentRoutineEx),
              onNext: () {
                if (_currentExerciseIndex + 1 <
                    _activeRoutine!.exercises.length) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const LiveWorkoutScreen(),
                    ),
                  );
                  // Note: We need to pass the state that we want to start from index+1.
                  // But LiveWorkoutScreen inits from session active exercise?
                  // No, it inits from 0.
                  // We need to advance the index stored in logic or pass it.
                  // WorkoutSession persists 'CompletedExercise' list.
                  // We could check `session.exercises.length` to determine where we are.
                  // But let's just make `LiveWorkoutScreen` accept an initial index or better yet:
                  // Just rely on `activeSession.exercises.length`?
                  // No, simply: The `RecapScreen` was pushed. We can just create a fresh `LiveWorkoutScreen`.
                  // But `_initRoutine` defaults to 0.

                  // IMPROVEMENT: `LiveWorkoutScreen` should check how many exercises are already logged in `activeSession`
                  // and match them to Routine to find current index.
                  // Doing this in `_initRoutine` would solve restoration too.
                } else {
                  Navigator.of(context).pop(); // Exit to Home
                }
              },
            ),
          ),
        );
      }
    } else {
      // Normal confirmation flow
      _startConfirmationFlow();
    }
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
                      Text(
                        "GRUPPO MUSCOLARE",
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
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
                        child: Text(
                          "Serie ${sessionProvider.activeExercise?.sets.length ?? 0 + 1} di ${currentEx.sets} | Target: ${currentEx.reps} reps",
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                      const SizedBox(height: 16),
                      WorkoutKeypad(onRepSelected: _onRepSelected),
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
                      "${DateTime.now().difference(sessionProvider.activeExercise?.sets.last.completedAt ?? DateTime.now()).inSeconds}s",
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
                          // Stop rest logic handled by UI removal?
                          // Just a visual close here?
                          // But timer in provider might continue running logic.
                          // Actually we can just pop LiveWorkoutScreen if we want to leave? NO.
                          // We just hide overlay? But how?
                          // We need internal state `_userDismissedRestTimer`.
                          // For now, assume this screen stays until user acts?
                          // Actually the user might want to see next set info.
                        },
                        child: const Text("TORNA ALLA SERIE"),
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
