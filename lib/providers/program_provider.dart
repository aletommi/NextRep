import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/program.dart';
import '../models/routine.dart';
import '../services/database_service.dart';

class ProgramProvider extends ChangeNotifier {
  final DatabaseService _db;

  List<Program> _programs = [];
  Program? _activeProgram;

  ProgramProvider(this._db) {
    _load();
  }

  void _load() {
    _programs = _db.getAllPrograms();
    _activeProgram = _db.getActiveProgram();
    notifyListeners();
  }

  List<Program> get programs => _programs;
  Program? get activeProgram => _activeProgram;

  /// Routines of the active program (what the workout tab shows).
  List<Routine> get activeRoutines => _activeProgram?.routines ?? [];

  Future<void> createProgram(String name, int routineCount) async {
    final routines = List.generate(routineCount, (i) {
      final letter = String.fromCharCode(65 + i); // A, B, C...
      return Routine(
        id: const Uuid().v4(),
        name: 'Routine $letter',
        exercises: [],
      );
    });

    final program = Program(
      id: const Uuid().v4(),
      name: name.trim(),
      createdAt: DateTime.now(),
      routines: routines,
    );

    await _db.saveProgram(program);
    if (_programs.isEmpty) {
      await _db.setActiveProgram(program.id);
    }
    _load();
  }

  Future<void> setActiveProgram(String programId) async {
    await _db.setActiveProgram(programId);
    _load();
  }

  /// Persists an edited routine. Routines are stored inside their program,
  /// so saving the program is enough.
  Future<void> saveRoutine(String programId, Routine routine) async {
    final program = _programs.where((p) => p.id == programId).firstOrNull;
    if (program == null) return;
    await program.save();
    _load();
  }

  Future<void> renameRoutine(
    String programId,
    Routine routine,
    String newName,
  ) async {
    final name = newName.trim();
    if (name.isEmpty) return;
    routine.name = name;
    await saveRoutine(programId, routine);
  }

  Future<void> deleteProgram(String programId) async {
    final wasActive = _activeProgram?.id == programId;
    await _db.deleteProgram(programId);
    final remaining = _db.getAllPrograms();
    if (wasActive && remaining.isNotEmpty) {
      await _db.setActiveProgram(remaining.first.id);
    }
    _load();
  }
}
