import 'package:hive/hive.dart';

part 'routine.g.dart';

@HiveType(typeId: 5)
class RoutineExercise extends HiveObject {
  @HiveField(0)
  final String exerciseId;

  @HiveField(1)
  final String sets;

  @HiveField(2)
  final String reps;

  @HiveField(3)
  final String? weight;

  @HiveField(4)
  final int? restTimeSeconds;

  @HiveField(5)
  final String? notes;

  RoutineExercise({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    this.weight,
    this.restTimeSeconds,
    this.notes,
  });
}

@HiveType(typeId: 4)
class Routine extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  final List<RoutineExercise> exercises; // Changed from exerciseIds

  @HiveField(3)
  final String? description;

  Routine({
    required this.id,
    required this.name,
    required this.exercises,
    this.description,
  });
}
