import 'package:isar/isar.dart';

part 'workout_session.g.dart';

@collection
class WorkoutSession {
  Id id = Isar.autoIncrement;

  late DateTime date;
  DateTime? endTime;

  late String routineName;

  /// Id of the routine this session was started from (null for old data).
  String? routineId;

  List<CompletedExercise> exercises = [];

  @ignore
  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);

  @ignore
  double get totalVolume => exercises.fold(0.0, (sum, e) => sum + e.volume);
}

@embedded
class CompletedExercise {
  late String exerciseName;
  late String muscleGroup;

  List<WorkoutSet> sets = [];

  @ignore
  double get volume =>
      sets.fold(0.0, (sum, s) => sum + (s.reps ?? 0) * (s.weight ?? 0));
}

@embedded
class WorkoutSet {
  int? setNumber;
  double? weight;
  int? reps;

  int? rpe;
  bool isWarmup = false;

  DateTime? completedAt;
}
