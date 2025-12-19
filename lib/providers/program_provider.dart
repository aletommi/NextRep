import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/program.dart';
import '../models/routine.dart';
import '../services/database_service.dart';

class ProgramProvider extends ChangeNotifier {
  final DatabaseService _databaseService;

  List<Program> _programs = [];
  Program? _activeProgram;

  ProgramProvider(this._databaseService) {
    loadInfo();
  }

  void loadInfo() {
    _programs = _databaseService.getAllPrograms();
    _activeProgram = _databaseService.getActiveProgram();
    notifyListeners();
  }

  List<Program> get programs => _programs;
  Program? get activeProgram => _activeProgram;

  Future<void> createProgram(String name, int routineCount) async {
    // Create Routines A, B, C...
    List<Routine> routines = [];
    for (int i = 0; i < routineCount; i++) {
      String routineLetter = String.fromCharCode(65 + i); // 65 is 'A'
      routines.add(
        Routine(
          id: const Uuid().v4(),
          name: "Routine $routineLetter",
          exercises: [],
        ),
      );
    }

    final newProgram = Program(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
      routines: routines,
      isActive: _programs.isEmpty, // Auto activate if first
    );

    // Save routines first? RoutineAdapter is standalone, but Program stores List<Routine>.
    // Hive stores nested objects if they are HiveObjects and registered.
    // However, DatabaseService.saveRoutine adds to 'routines' box.
    // If Program has List<Routine>, does it reference them or copy them?
    // It depends on if we store HiveList or just List.
    // Program model uses List<Routine>. Routine extends HiveObject.
    // We should probably save them to the routine box as well to be safe and consistent,
    // or rely on Hive's capability to store objects.
    // Given the architecture, let's save them to the routine box to be safe
    // and ensuring valid IDs.

    for (var r in routines) {
      await _databaseService.saveRoutine(r);
    }

    await _databaseService.saveProgram(newProgram);
    if (newProgram.isActive) {
      await _databaseService.setActiveProgram(newProgram.id);
    }

    loadInfo();
  }

  Future<void> setActiveProgram(String programId) async {
    await _databaseService.setActiveProgram(programId);
    loadInfo();
  }

  Future<void> updateRoutine(String programId, Routine updatedRoutine) async {
    // 1. Auto-Rename Logic based on Muscle Groups
    final exercises = updatedRoutine.exercises;
    if (exercises.isNotEmpty) {
      final Set<String> muscleGroups = {};

      for (var routineExercise in exercises) {
        // Fetch full exercise to get muscle group
        final exercise = _databaseService.exercisesBox.get(
          routineExercise.exerciseId,
        );
        if (exercise != null) {
          muscleGroups.add(exercise.muscleGroup);
        }
      }

      if (muscleGroups.isNotEmpty) {
        // Sort to be consistent
        final sortedMuscles = muscleGroups.toList()..sort();
        updatedRoutine.name = sortedMuscles.join(
          " - ",
        ); // e.g. "Petto - Bicipiti"
      }
    }

    // 2. Persist Changes
    // Save routine to its own box (important for consistency)
    await updatedRoutine.save();

    // 3. Update Program reference (if needed due to Hive behavior)
    final program = _programs.firstWhere((p) => p.id == programId);
    await program.save();

    loadInfo();
  }

  Future<void> deleteProgram(String programId) async {
    // Logic to delete program
    // For now just basic removal
    final program = _programs.firstWhere((p) => p.id == programId);
    await program.delete();
    loadInfo();
  }
}
