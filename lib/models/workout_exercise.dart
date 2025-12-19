import 'package:hive/hive.dart';
import 'workout_set.dart';

part 'workout_exercise.g.dart';

@HiveType(typeId: 2)
class WorkoutExercise extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String exerciseId; // Reference to Exercise

  @HiveField(2)
  final String exerciseName; // Denormalized for easier display

  @HiveField(3)
  List<WorkoutSet> sets;

  @HiveField(4)
  String? notes;

  WorkoutExercise({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    this.notes,
  });
}
