import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/workout.dart';
import '../models/routine.dart';

class WorkoutProvider extends ChangeNotifier {
  final DatabaseService _databaseService;

  List<Workout> _workouts = [];
  List<Routine> _routines = [];

  WorkoutProvider(this._databaseService) {
    loadData();
  }

  void loadData() {
    _workouts = _databaseService.getAllWorkouts();

    // Load routines from active program if exists, else empty or fallback
    final activeProgram = _databaseService.getActiveProgram();
    if (activeProgram != null) {
      _routines = activeProgram.routines;
    } else {
      _routines = [];
      // Or fallback to all routines if we want backwards compatibility?
      // Let's stick to new logic: No active program = No routines in rotation.
    }
    notifyListeners();
  }

  List<Workout> get workouts => _workouts;
  List<Routine> get routines => _routines;

  Routine? get nextRoutine {
    if (_routines.isEmpty) return null;
    if (_workouts.isEmpty) return _routines.first;

    final lastWorkoutName = _workouts.first.name;
    // Find index of routine with same name
    // This assumes workout name == routine name. Ideally we store routineId in Workout.
    // For now, let's match by name or fallback.
    final index = _routines.indexWhere((r) => r.name == lastWorkoutName);

    if (index == -1) {
      return _routines.first; // Last workout wasn't based on current routines
    }

    // Rotate
    final nextIndex = (index + 1) % _routines.length;
    return _routines[nextIndex];
  }

  // Smart Feed Logic (Mock/Simple for now)
  List<String> get smartFeed {
    if (_workouts.length < 2) {
      return ["Benvenuto! Inizia ad allenarti per vedere i tuoi progressi."];
    }

    final last = _workouts.first;
    // Compare specific exercises with previous history...
    // This would require more complex comparison logic.
    // Returning a placeholder for the UI task verification.
    return [
      "Ottimo lavoro nell'ultimo allenamento!",
      "Hai completato ${last.exercises.length} esercizi.",
    ];
  }

  Future<void> addRoutine(Routine routine) async {
    await _databaseService.saveRoutine(routine);
    loadData();
  }
}
