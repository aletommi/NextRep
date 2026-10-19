import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/workout_session.dart';
import '../models/exercise.dart';
import '../models/routine.dart';
import '../models/program.dart';

/// Local storage: programs and exercises live in Hive, workout sessions in Isar.
class DatabaseService {
  static const String exerciseBoxName = 'exercises';
  static const String programBoxName = 'programs';
  static const String authBoxName = 'auth';

  late Isar isar;

  Future<void> init() async {
    await Hive.initFlutter();

    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([WorkoutSessionSchema], directory: dir.path);

    Hive.registerAdapter(ExerciseAdapter());
    Hive.registerAdapter(RoutineExerciseAdapter());
    Hive.registerAdapter(RoutineAdapter());
    Hive.registerAdapter(ProgramAdapter());

    await Hive.openBox<Exercise>(exerciseBoxName);
    await Hive.openBox<Program>(programBoxName);
    await Hive.openBox(authBoxName);

    await _seedInitialExercises();
  }

  static const List<String> muscleGroups = [
    'Petto',
    'Schiena',
    'Gambe',
    'Spalle',
    'Bicipiti',
    'Tricipiti',
    'Addome',
  ];

  Future<void> _seedInitialExercises() async {
    // Old installs used English categories: reset so the picker is consistent.
    if (exercisesBox.values.any(
      (e) =>
          e.muscleGroup == 'Chest' ||
          e.muscleGroup == 'Arms' ||
          e.muscleGroup == 'Braccia',
    )) {
      await exercisesBox.clear();
    }

    if (exercisesBox.isNotEmpty) return;

    const seed = <String, List<String>>{
      'Petto': [
        'Panca Piana (Barbell Bench Press)',
        'Panca Inclinata (Incline Bench Press)',
        'Panca Declinata (Decline Bench Press)',
        'Spinte con Manubri (Dumbbell Press)',
        'Croci (Chest Flyes)',
        'Dips (Parallele)',
        'Push-ups (Piegamenti)',
        'Chest Press Machine',
      ],
      'Schiena': [
        'Stacco da Terra (Deadlift)',
        'Trazioni alla sbarra (Pull-ups)',
        'Chin-ups',
        'Lat Machine (Lat Pulldown)',
        'Rematore Bilanciere (Barbell Row)',
        'Rematore Manubrio (Dumbbell Row)',
        'Pulley Basso (Seated Cable Row)',
        'Pullover',
      ],
      'Gambe': [
        'Squat (Back Squat)',
        'Front Squat',
        'Leg Press',
        'Affondi (Lunges)',
        'Bulgarian Split Squat',
        'Leg Extension',
        'Stacchi Rumeni (RDL)',
        'Leg Curl',
        'Hip Thrust',
        'Glute Bridge',
        'Calf Raise',
      ],
      'Spalle': [
        'Military Press (Overhead Press)',
        'Dumbbell Shoulder Press',
        'Arnold Press',
        'Alzate Laterali (Lateral Raises)',
        'Alzate Frontali',
        'Alzate Posteriori (Rear Delt Flyes)',
        'Face Pulls',
      ],
      'Bicipiti': [
        'Curl Bilanciere (Barbell Curl)',
        'Curl Manubri (Dumbbell Curl)',
        'Hammer Curl',
        'Preacher Curl (Panca Scott)',
        'Spider Curl',
      ],
      'Tricipiti': [
        'Pushdown ai cavi',
        'French Press (Skullcrushers)',
        'Estensioni dietro la nuca',
        'Panca presa stretta',
      ],
      'Addome': ['Plank', 'Crunch', 'Leg Raise', 'Russian Twist', 'Ab Wheel'],
    };

    for (final entry in seed.entries) {
      for (final name in entry.value) {
        final exercise = Exercise(
          id: const Uuid().v4(),
          name: name,
          muscleGroup: entry.key,
        );
        await exercisesBox.put(exercise.id, exercise);
      }
    }
  }

  // --- Exercises ---
  Box<Exercise> get exercisesBox => Hive.box<Exercise>(exerciseBoxName);

  List<Exercise> getAllExercises() => exercisesBox.values.toList();

  Exercise? getExercise(String id) => exercisesBox.get(id);

  Future<void> addExercise(Exercise exercise) =>
      exercisesBox.put(exercise.id, exercise);

  // --- Programs ---
  Box<Program> get programsBox => Hive.box<Program>(programBoxName);

  List<Program> getAllPrograms() => programsBox.values.toList();

  Future<void> saveProgram(Program program) =>
      programsBox.put(program.id, program);

  Future<void> deleteProgram(String programId) => programsBox.delete(programId);

  Future<void> setActiveProgram(String programId) async {
    for (final p in programsBox.values) {
      final shouldBeActive = p.id == programId;
      if (p.isActive != shouldBeActive) {
        p.isActive = shouldBeActive;
        await p.save();
      }
    }
  }

  Program? getActiveProgram() {
    for (final p in programsBox.values) {
      if (p.isActive) return p;
    }
    return null;
  }

  // --- Workout sessions (Isar) ---
  Future<void> saveSession(WorkoutSession session) async {
    await isar.writeTxn(() => isar.workoutSessions.put(session));
  }

  Future<void> deleteSession(int id) async {
    await isar.writeTxn(() => isar.workoutSessions.delete(id));
  }

  /// Sessions with at least one logged set, newest first.
  Future<List<WorkoutSession>> getCompletedSessions() async {
    final all = await isar.workoutSessions.where().sortByDateDesc().findAll();
    return all.where((s) => s.totalSets > 0).toList();
  }

  // --- Auth flag (local only) ---
  Box get authBox => Hive.box(authBoxName);
}
