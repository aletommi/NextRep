import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../models/workout_session.dart';
import '../models/routine.dart';
import '../services/database_service.dart';

class WorkoutSessionProvider extends ChangeNotifier {
  final DatabaseService _databaseService;

  WorkoutSession? _activeSession;
  CompletedExercise? _activeExercise;

  WorkoutSession? get activeSession => _activeSession;
  CompletedExercise? get activeExercise => _activeExercise;

  // Timer logic
  // DateTime? _timerStartTime; // Moved to bottom with restStartTime
  // int _elapsedSeconds = 0; // Removed unused field

  // int get elapsedSeconds => _elapsedSeconds; // Removed unused getter

  WorkoutSessionProvider(this._databaseService);

  Future<void> startSession(String routineName) async {
    final newSession = WorkoutSession()
      ..date = DateTime.now()
      ..routineName = routineName
      ..exercises = [];

    await _databaseService.isar.writeTxn(() async {
      await _databaseService.isar.workoutSessions.put(newSession);
    });

    _activeSession = newSession;
    notifyListeners();
  }

  void setActiveExercise(String exerciseName, String muscleGroup) {
    if (_activeSession == null) return;

    // Check if exercise already exists in this session
    // If we switch back and forth, we might want to continue adding to the existing one.
    // For now, let's find the last occurrence or create new.

    var existing = _activeSession!.exercises
        .where((e) => e.exerciseName == exerciseName)
        .lastOrNull;

    if (existing == null) {
      // It's a structured list, so we might want to just create a 'pointer' to a new object
      // But Isar embedded objects are stored inside the parent list.
      // We'll create a new CompletedExercise and add it to the list.
      final newExercise = CompletedExercise()
        ..exerciseName = exerciseName
        ..muscleGroup = muscleGroup
        ..sets = [];

      // We don't save immediately here, we save when we add a set?
      // Or we can save immediately to be safe.
      // Let's just track it locally until the first set is added to avoid empty exercises?
      // The prompt says "Appena entri nell'esercizio, il sistema crea un oggetto temporaneo".

      existing = newExercise;

      // Temporarily add to session?
      // We need to persist it if we want to be crash-proof.
      // Let's persist.
      // But wait, Isar embedded objects are part of the main object.
      // We need to update the main session object.
    }

    _activeExercise = existing;
    notifyListeners();
  }

  Future<void> addSet(int reps, double weight) async {
    if (_activeSession == null || _activeExercise == null) return;

    final newSet = WorkoutSet()
      ..setNumber = _activeExercise!.sets.length + 1
      ..reps = reps
      ..weight = weight
      ..completedAt = DateTime.now();

    // Add set to active exercise
    _activeExercise!.sets = [..._activeExercise!.sets, newSet];

    // Update active session's exercise list
    // If this is a new exercise object (not in list yet), add it.
    // If it is in list, update it?
    // With Isar embedded objects, modifying the list in memory and then putting the parent object works.

    // Check if _activeExercise is already in _activeSession.exercises
    if (!_activeSession!.exercises.contains(_activeExercise)) {
      _activeSession!.exercises = [
        ..._activeSession!.exercises,
        _activeExercise!,
      ];
    } else {
      // It's already there (reference), but we need to trigger Isar update used the list assignment above?
      // Since it's in memory, the reference in the list is updated if _activeExercise is the *same object*.
      // But we just did `_activeExercise!.sets = ...` which modifies the object.
      // So the object inside the list is modified (if it's the exact same instance).
      // Let's be explicit.
      final index = _activeSession!.exercises.indexOf(_activeExercise!);
      if (index != -1) {
        _activeSession!.exercises[index] = _activeExercise!;
      }
    }

    // Persist immediately
    await _databaseService.isar.writeTxn(() async {
      await _databaseService.isar.workoutSessions.put(_activeSession!);
    });

    // Start Rest Timer Logic here or in UI?
    // Prompt says: "Immediatamente succedono 3 cose... Start Timer... Salvataggio... Richiesta Peso".
    // We handle saving here. Timer can be triggered here.
    startRestTimer();

    notifyListeners();
  }

  Future<void> updateLastSetWeight(double newWeight) async {
    if (_activeSession == null ||
        _activeExercise == null ||
        _activeExercise!.sets.isEmpty) {
      return;
    }

    // Update memory
    _activeExercise!.sets.last.weight = newWeight;

    // Persist
    // We need to re-save the session to update the embedded list
    // Ensure the main session object reflects the change (it should as it holds reference)
    await _databaseService.isar.writeTxn(() async {
      await _databaseService.isar.workoutSessions.put(_activeSession!);
    });

    notifyListeners();
  }

  // Weight Suggestion Logic
  Future<double?> getSuggestedWeight(
    String exerciseName,
    int currentSetIndex,
  ) async {
    // 1. Check previous set in CURRENT session
    if (_activeExercise != null &&
        _activeExercise!.sets.length > currentSetIndex) {
      // logic hard to define if we are calling this BEFORE adding the set?
      // Use case: user hasn't done the set yet. 'currentSetIndex' is what they are about to do.
      // Wait, the prompt says: "suggestion when user passes from Set 1 to Set 2".
      // So if I am about to do Set 2 (index 1), look at Set 1 (index 0).
      if (currentSetIndex > 0) {
        return _activeExercise!.sets[currentSetIndex - 1].weight;
      }
    }

    // 2. Ghost Log (Previous Session)
    // Find last session that had this exercise
    // We need to query Isar.

    final lastSession = await _databaseService.isar.workoutSessions
        .filter()
        .exercisesElement((q) => q.exerciseNameEqualTo(exerciseName))
        .sortByDateDesc()
        .findFirst();

    if (lastSession != null) {
      final oldExercise = lastSession.exercises.firstWhere(
        (e) => e.exerciseName == exerciseName,
      );
      // Try to find matching set index
      if (currentSetIndex < oldExercise.sets.length) {
        return oldExercise.sets[currentSetIndex].weight;
      }
      // Or return last used weight
      if (oldExercise.sets.isNotEmpty) {
        return oldExercise.sets.last.weight;
      }
    }

    return null; // No history
  }

  // Comparison Logic for Recap
  Future<Map<String, dynamic>> getExerciseStats(String exerciseName) async {
    final currentEx = _activeSession?.exercises
        .where((e) => e.exerciseName == exerciseName)
        .lastOrNull;
    if (currentEx == null) return {};

    // 1. Calculate Aquired Volume (Actual)
    double calculateVolume(CompletedExercise ex) {
      return ex.sets.fold(0.0, (sum, s) {
        final r = s.reps ?? 0;
        final w = s.weight ?? 0.0;
        return sum + (r * w);
      });
    }

    final currentVolume = calculateVolume(currentEx);
    double targetVolume = 0.0;
    bool hasTarget = false;

    // 2. Fetch Routine Target
    if (_activeSession?.routineName != null) {
      try {
        final routine = _databaseService.routinesBox.values.firstWhere(
          (r) => r.name == _activeSession!.routineName,
        );

        // Find specific exercise in routine
        // We have exerciseName, but routine uses exerciseIds.
        // We need to match by resolving IDs.
        RoutineExercise? targetRx;
        for (var rx in routine.exercises) {
          final exDef = _databaseService.exercisesBox.get(rx.exerciseId);
          if (exDef?.name == exerciseName) {
            targetRx = rx;
            break;
          }
        }

        if (targetRx != null) {
          hasTarget = true;
          final setsCount = int.tryParse(targetRx.sets) ?? 1;

          // Helper to parse comma separated "10,8,6"
          double parseVal(String? src, int index) {
            if (src == null || src.isEmpty) return 0.0;
            final parts = src.split(',').map((e) => e.trim()).toList();
            if (parts.isEmpty) return 0.0;
            if (index < parts.length) {
              return double.tryParse(parts[index]) ?? 0.0;
            }
            return double.tryParse(parts.last) ?? 0.0;
          }

          for (int i = 0; i < setsCount; i++) {
            final r = parseVal(targetRx.reps, i);
            final w = parseVal(targetRx.weight, i);
            targetVolume += (r * w);
          }
        }
      } catch (e) {
        // Routine not found or other mismatch
      }
    }

    // 3. Logic for Improvement/Worsening vs TARGET
    double percentChange = 0.0;
    String statusLabel = "Nessun Target";
    String secondaryLabel = "N/A";

    if (hasTarget && targetVolume > 0) {
      if (currentVolume == targetVolume) {
        statusLabel = "Target Raggiunto";
      } else {
        percentChange = ((currentVolume - targetVolume) / targetVolume) * 100;
        if (percentChange > 0) {
          statusLabel = "Migliorato del ${percentChange.toStringAsFixed(1)}%";
        } else {
          statusLabel =
              "Peggiorato del ${percentChange.abs().toStringAsFixed(1)}%";
        }
      }
      secondaryLabel = "vs Target ${targetVolume.toStringAsFixed(0)}";
    } else {
      if (!hasTarget) {
        statusLabel = "Fuori Programma";
      } else {
        statusLabel = "Target non calc."; // weight might be 0
      }
    }

    // Append % to current volume display if relevant
    String shortPercent = "";
    if (hasTarget && targetVolume > 0 && currentVolume != targetVolume) {
      if (percentChange > 0) {
        shortPercent = " (+${percentChange.toStringAsFixed(1)}%)";
      } else {
        shortPercent = " (${percentChange.toStringAsFixed(1)}%)";
      }
    }

    return {
      'weightDiff': '${(currentVolume - targetVolume).toStringAsFixed(1)} vol',
      'weightLabel': statusLabel,
      'repsDiff':
          'Vol (Kg x Reps): ${currentVolume.toStringAsFixed(0)}$shortPercent',
      'repsLabel': secondaryLabel,
    };
  }

  // Timer Logic
  DateTime? _restStartTime;
  bool _isTimerRunning = false;

  DateTime? get restStartTime => _restStartTime;
  bool get isTimerRunning => _isTimerRunning;

  void startRestTimer() {
    _restStartTime = DateTime.now();
    _isTimerRunning = true;
    notifyListeners();
  }

  void stopRestTimer() {
    _isTimerRunning = false;
    _restStartTime = null;
    notifyListeners();
  }
}
