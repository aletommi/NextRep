import 'package:hive/hive.dart';
import 'workout_exercise.dart';

part 'workout.g.dart';

@HiveType(typeId: 3)
class Workout extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name; // e.g., "Push Day"

  @HiveField(2)
  final DateTime startTime;

  @HiveField(3)
  DateTime? endTime;

  @HiveField(4)
  List<WorkoutExercise> exercises;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  int? durationInSeconds;

  Workout({
    required this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    required this.exercises,
    this.notes,
    this.durationInSeconds,
  });
}
