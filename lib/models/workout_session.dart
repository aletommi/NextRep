import 'package:isar/isar.dart';

part 'workout_session.g.dart';

@collection
class WorkoutSession {
  Id id = Isar.autoIncrement;

  late DateTime date;
  DateTime? endTime;

  late String routineName;

  // Link to the original routine ID if needed for analytics, though the user didn't explicitly ask for it,
  // keeping it simple as per prompt "routineName"

  List<CompletedExercise> exercises = [];
}

@embedded
class CompletedExercise {
  late String exerciseName;
  late String muscleGroup;

  List<WorkoutSet> sets = [];
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
