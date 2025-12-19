import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../models/routine.dart';
import 'widgets/exercise_focus_view.dart';

class WorkoutScreen extends StatefulWidget {
  final Routine? routine; // If starting from a routine

  const WorkoutScreen({super.key, this.routine});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  // Logic to track sets, etc.
  // Ideally this state should be in a separate Provider (ActiveWorkoutProvider)
  // to persist across accidental navigation, but for simplicity we keep it here.

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    _pageController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If no routine provided (Quick Start), we need to handle that.
    if (widget.routine == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Allenamento Libero")),
        body: const Center(child: Text("Quick Start non ancora implementato.")),
      );
    }

    final routine = widget.routine!;

    return Scaffold(
      appBar: AppBar(
        title: Text(routine.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              // Finish workout
              Navigator.pop(context); // Mock finish
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: (_currentPage + 1) / routine.exercises.length,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: routine.exercises.length,
              onPageChanged: (idx) {
                setState(() {
                  _currentPage = idx;
                });
              },
              itemBuilder: (context, index) {
                final routineExercise = routine.exercises[index];
                return ExerciseFocusView(
                  exerciseId: routineExercise.exerciseId,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
