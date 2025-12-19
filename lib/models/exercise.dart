import 'package:hive/hive.dart';

part 'exercise.g.dart';

@HiveType(typeId: 0)
class Exercise extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String muscleGroup; // Chest, Back, Legs, etc.

  @HiveField(3)
  final String type; // 'reps', 'time'

  @HiveField(4)
  final String? notes;

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.type = 'reps',
    this.notes,
  });
}
