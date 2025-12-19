import 'package:hive/hive.dart';

part 'workout_set.g.dart';

@HiveType(typeId: 1)
class WorkoutSet extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  double? weight;

  @HiveField(2)
  int? reps;

  @HiveField(3)
  int? timeInSeconds;

  @HiveField(4)
  double? rpe; // Rate of Perceived Exertion (1-10)

  @HiveField(5)
  bool isCompleted;

  WorkoutSet({
    required this.id,
    this.weight,
    this.reps,
    this.timeInSeconds,
    this.rpe,
    this.isCompleted = false,
  });
}
