import 'package:hive/hive.dart';
import 'routine.dart';

part 'program.g.dart';

@HiveType(typeId: 6)
class Program extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  bool isActive;

  @HiveField(4)
  final List<Routine> routines;

  Program({
    required this.id,
    required this.name,
    required this.createdAt,
    this.isActive = false,
    required this.routines,
  });
}
