import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/workout_session.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/workout_set.dart';
import '../models/workout_exercise.dart';
import '../models/routine.dart';
import '../models/program.dart';

class DatabaseService {
  static const String exerciseBoxName = 'exercises';
  static const String workoutBoxName = 'workouts';
  static const String routineBoxName = 'routines';
  static const String programBoxName = 'programs';

  late Isar isar;

  Future<void> init() async {
    await Hive.initFlutter();

    // Initialize Isar
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([WorkoutSessionSchema], directory: dir.path);

    // Register Adapters
    Hive.registerAdapter(ExerciseAdapter());
    Hive.registerAdapter(WorkoutSetAdapter());
    Hive.registerAdapter(WorkoutExerciseAdapter());
    Hive.registerAdapter(WorkoutAdapter());
    Hive.registerAdapter(RoutineExerciseAdapter());
    Hive.registerAdapter(RoutineAdapter());
    Hive.registerAdapter(ProgramAdapter());

    // Open Boxes
    await Hive.openBox<Exercise>(exerciseBoxName);
    await Hive.openBox<Workout>(workoutBoxName);
    await Hive.openBox<Routine>(routineBoxName);
    await Hive.openBox<Program>(programBoxName);

    _seedInitialExercises();
  }

  Future<void> _seedInitialExercises() async {
    // Migration: If we find old English categories OR combined Braccia, clear and re-seed
    if (exercisesBox.values.any(
      (e) =>
          e.muscleGroup == 'Chest' ||
          e.muscleGroup == 'Arms' ||
          e.muscleGroup == 'Braccia',
    )) {
      await exercisesBox.clear();
      // Also clear routines as they reference IDs that might be lost?
      // Actually, since we generate new IDs, old routines would point to dead IDs.
      // Ideally we'd keep IDs stable, but for this dev phase, clearing is acceptable.
    }

    if (exercisesBox.isEmpty) {
      final exercises = [
        // Petto (Chest)
        Exercise(
          id: const Uuid().v4(),
          name: 'Panca Piana (Barbell Bench Press)',
          muscleGroup: 'Petto',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Panca Inclinata (Incline Bench Press)',
          muscleGroup: 'Petto',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Panca Declinata (Decline Bench Press)',
          muscleGroup: 'Petto',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Spinte con Manubri (Dumbbell Press)',
          muscleGroup: 'Petto',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Croci (Chest Flyes)',
          muscleGroup: 'Petto',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Dips (Parallele)',
          muscleGroup: 'Petto',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Push-ups (Piegamenti)',
          muscleGroup: 'Petto',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Chest Press Machine',
          muscleGroup: 'Petto',
        ),

        // Schiena (Back)
        Exercise(
          id: const Uuid().v4(),
          name: 'Stacco da Terra (Deadlift)',
          muscleGroup: 'Schiena',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Trazioni alla sbarra (Pull-ups)',
          muscleGroup: 'Schiena',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Chin-ups',
          muscleGroup: 'Schiena',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Lat Machine (Lat Pulldown)',
          muscleGroup: 'Schiena',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Rematore Bilanciere (Barbell Row)',
          muscleGroup: 'Schiena',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Rematore Manubrio (Dumbbell Row)',
          muscleGroup: 'Schiena',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Pulley Basso (Seated Cable Row)',
          muscleGroup: 'Schiena',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Pullover',
          muscleGroup: 'Schiena',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Face Pulls',
          muscleGroup: 'Spalle',
        ), // Often trained with shoulders
        // Gambe (Legs)
        Exercise(
          id: const Uuid().v4(),
          name: 'Squat (Back Squat)',
          muscleGroup: 'Gambe',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Front Squat',
          muscleGroup: 'Gambe',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Leg Press',
          muscleGroup: 'Gambe',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Affondi (Lunges)',
          muscleGroup: 'Gambe',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Bulgarian Split Squat',
          muscleGroup: 'Gambe',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Leg Extension',
          muscleGroup: 'Gambe',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Stacchi Rumeni (RDL)',
          muscleGroup: 'Gambe',
        ),
        Exercise(id: const Uuid().v4(), name: 'Leg Curl', muscleGroup: 'Gambe'),
        Exercise(
          id: const Uuid().v4(),
          name: 'Hip Thrust',
          muscleGroup: 'Gambe',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Glute Bridge',
          muscleGroup: 'Gambe',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Calf Raise',
          muscleGroup: 'Gambe',
        ),

        // Spalle (Shoulders)
        Exercise(
          id: const Uuid().v4(),
          name: 'Military Press (Overhead Press)',
          muscleGroup: 'Spalle',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Dumbbell Shoulder Press',
          muscleGroup: 'Spalle',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Arnold Press',
          muscleGroup: 'Spalle',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Alzate Laterali (Lateral Raises)',
          muscleGroup: 'Spalle',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Alzate Frontali',
          muscleGroup: 'Spalle',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Alzate Posteriori (Rear Delt Flyes)',
          muscleGroup: 'Spalle',
        ),

        // Bicipiti
        Exercise(
          id: const Uuid().v4(),
          name: 'Curl Bilanciere (Barbell Curl)',
          muscleGroup: 'Bicipiti',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Curl Manubri (Dumbbell Curl)',
          muscleGroup: 'Bicipiti',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Hammer Curl',
          muscleGroup: 'Bicipiti',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Preacher Curl (Panca Scott)',
          muscleGroup: 'Bicipiti',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Spider Curl',
          muscleGroup: 'Bicipiti',
        ),

        // Tricipiti
        Exercise(
          id: const Uuid().v4(),
          name: 'Pushdown ai cavi',
          muscleGroup: 'Tricipiti',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'French Press (Skullcrushers)',
          muscleGroup: 'Tricipiti',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Estensioni dietro la nuca',
          muscleGroup: 'Tricipiti',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Panca presa stretta',
          muscleGroup: 'Tricipiti',
        ),

        // Addome (Abs)
        Exercise(id: const Uuid().v4(), name: 'Plank', muscleGroup: 'Addome'),
        Exercise(id: const Uuid().v4(), name: 'Crunch', muscleGroup: 'Addome'),
        Exercise(
          id: const Uuid().v4(),
          name: 'Leg Raise',
          muscleGroup: 'Addome',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Russian Twist',
          muscleGroup: 'Addome',
        ),
        Exercise(
          id: const Uuid().v4(),
          name: 'Ab Wheel',
          muscleGroup: 'Addome',
        ),
      ];

      for (var exercise in exercises) {
        exercisesBox.put(exercise.id, exercise);
      }
    }
  }

  // --- Exercises ---
  Box<Exercise> get exercisesBox => Hive.box<Exercise>(exerciseBoxName);

  List<Exercise> getAllExercises() {
    return exercisesBox.values.toList();
  }

  Future<void> addExercise(Exercise exercise) async {
    await exercisesBox.put(exercise.id, exercise);
  }

  // --- Workouts ---
  Box<Workout> get workoutsBox => Hive.box<Workout>(workoutBoxName);

  List<Workout> getAllWorkouts() {
    // Sort by date descending
    final workouts = workoutsBox.values.toList();
    workouts.sort((a, b) => b.startTime.compareTo(a.startTime));
    return workouts;
  }

  Future<void> saveWorkout(Workout workout) async {
    await workoutsBox.put(workout.id, workout);
  }

  // --- Routines ---
  Box<Routine> get routinesBox => Hive.box<Routine>(routineBoxName);

  List<Routine> getAllRoutines() {
    return routinesBox.values.toList();
  }

  Future<void> saveRoutine(Routine routine) async {
    await routinesBox.put(routine.id, routine);
  }

  // --- Programs ---
  Box<Program> get programsBox => Hive.box<Program>(programBoxName);

  List<Program> getAllPrograms() {
    return programsBox.values.toList();
  }

  Future<void> saveProgram(Program program) async {
    await programsBox.put(program.id, program);
  }

  Future<void> setActiveProgram(String programId) async {
    // Deactivate all
    for (var p in programsBox.values) {
      if (p.isActive) {
        p.isActive = false;
        await p.save();
      }
    }
    // Activate target
    final program = programsBox.get(programId);
    if (program != null) {
      program.isActive = true;
      await program.save();
    }
  }

  Program? getActiveProgram() {
    try {
      return programsBox.values.firstWhere((p) => p.isActive);
    } catch (e) {
      return null;
    }
  }
}
