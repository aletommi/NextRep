import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../core/utils/targets.dart';
import '../models/exercise.dart';
import '../models/routine.dart';
import '../models/workout_session.dart';
import '../services/database_service.dart';

/// Result of comparing an exercise just completed with its routine target.
class ExerciseStats {
  final double volume;
  final double? targetVolume;

  const ExerciseStats({required this.volume, this.targetVolume});

  /// Percent difference vs target, null when there is no target.
  double? get percentChange {
    final t = targetVolume;
    if (t == null || t <= 0) return null;
    return (volume - t) / t * 100;
  }
}

class WorkoutSessionProvider extends ChangeNotifier {
  final DatabaseService _db;

  WorkoutSession? _activeSession;
  CompletedExercise? _activeExercise;
  List<WorkoutSession> _history = [];

  WorkoutSessionProvider(this._db) {
    loadHistory();
  }

  WorkoutSession? get activeSession => _activeSession;
  CompletedExercise? get activeExercise => _activeExercise;

  /// Completed sessions, newest first.
  List<WorkoutSession> get history => _history;

  Future<void> loadHistory() async {
    _history = await _db.getCompletedSessions();
    notifyListeners();
  }

  // --- Rotation ---

  /// The routine to do next: the one after the last completed routine in
  /// the program order, or the first one if there is no history.
  Routine? nextRoutine(List<Routine> routines) {
    if (routines.isEmpty) return null;
    if (_history.isEmpty) return routines.first;

    final last = _history.first;
    var index = routines.indexWhere((r) => r.id == last.routineId);
    if (index == -1) {
      index = routines.indexWhere((r) => r.name == last.routineName);
    }
    if (index == -1) return routines.first;
    return routines[(index + 1) % routines.length];
  }

  // --- Session lifecycle ---

  Future<void> startSession(Routine routine) async {
    final session = WorkoutSession()
      ..date = DateTime.now()
      ..routineName = routine.name
      ..routineId = routine.id
      ..exercises = [];

    await _db.saveSession(session);

    _activeSession = session;
    _activeExercise = null;
    stopRestTimer();
    notifyListeners();
  }

  /// Closes the active session. Sessions with no logged set are discarded.
  Future<void> endSession() async {
    final session = _activeSession;
    if (session == null) return;

    if (session.totalSets == 0) {
      await _db.deleteSession(session.id);
    } else {
      session.endTime = DateTime.now();
      await _db.saveSession(session);
    }

    _activeSession = null;
    _activeExercise = null;
    stopRestTimer();
    await loadHistory();
  }

  void setActiveExercise(Exercise exercise) {
    final session = _activeSession;
    if (session == null) return;

    // A new entry per exercise visit, so the same exercise can appear twice
    // in a routine. It is added to the session on the first logged set.
    _activeExercise = CompletedExercise()
      ..exerciseName = exercise.name
      ..muscleGroup = exercise.muscleGroup
      ..sets = [];
    notifyListeners();
  }

  Future<void> addSet(int reps, double weight) async {
    final session = _activeSession;
    final exercise = _activeExercise;
    if (session == null || exercise == null) return;

    final newSet = WorkoutSet()
      ..setNumber = exercise.sets.length + 1
      ..reps = reps
      ..weight = weight
      ..completedAt = DateTime.now();

    exercise.sets = [...exercise.sets, newSet];
    if (!session.exercises.contains(exercise)) {
      session.exercises = [...session.exercises, exercise];
    }

    await _db.saveSession(session);
    startRestTimer();
    notifyListeners();
  }

  Future<void> updateLastSetWeight(double newWeight) async {
    final session = _activeSession;
    final exercise = _activeExercise;
    if (session == null || exercise == null || exercise.sets.isEmpty) return;

    exercise.sets.last.weight = newWeight;
    await _db.saveSession(session);
    notifyListeners();
  }

  // --- Suggestions & stats ---

  /// Weight to propose for the set the user is about to do: the previous set
  /// in this session, otherwise the matching set from the last session with
  /// this exercise.
  Future<double?> getSuggestedWeight(
    String exerciseName,
    int currentSetIndex,
  ) async {
    final current = _activeExercise;
    if (current != null && currentSetIndex > 0 && current.sets.isNotEmpty) {
      return current.sets.last.weight;
    }

    final lastSession = await _db.isar.workoutSessions
        .filter()
        .exercisesElement((q) => q.exerciseNameEqualTo(exerciseName))
        .sortByDateDesc()
        .findFirst();
    if (lastSession == null) return null;

    final old = lastSession.exercises
        .where((e) => e.exerciseName == exerciseName)
        .lastOrNull;
    if (old == null || old.sets.isEmpty) return null;

    if (currentSetIndex < old.sets.length) {
      return old.sets[currentSetIndex].weight;
    }
    return old.sets.last.weight;
  }

  /// Compares the volume done for [exerciseName] in this session with the
  /// routine target.
  ExerciseStats getExerciseStats(String exerciseName, RoutineExercise target) {
    final done = _activeSession?.exercises
        .where((e) => e.exerciseName == exerciseName)
        .lastOrNull;
    final volume = done?.volume ?? 0;

    final targetVol = targetVolume(
      sets: target.sets,
      reps: target.reps,
      weight: target.weight,
    );

    return ExerciseStats(
      volume: volume,
      targetVolume: targetVol > 0 ? targetVol : null,
    );
  }

  // --- Dashboard helpers ---

  int get totalWorkouts => _history.length;

  int get workoutsThisWeek {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return _history.where((s) => !s.date.isBefore(startOfWeek)).length;
  }

  WorkoutSession? get lastWorkout => _history.firstOrNull;

  // --- Rest timer ---
  DateTime? _restStartTime;

  DateTime? get restStartTime => _restStartTime;
  bool get isTimerRunning => _restStartTime != null;

  void startRestTimer() {
    _restStartTime = DateTime.now();
    notifyListeners();
  }

  void stopRestTimer() {
    if (_restStartTime == null) return;
    _restStartTime = null;
    notifyListeners();
  }
}
