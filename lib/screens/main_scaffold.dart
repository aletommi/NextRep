import 'package:flutter/material.dart';
import '../core/constants/strings.dart';
import 'dashboard/dashboard_screen.dart';
import 'programs/programs_screen.dart';
import 'workout/workout_preview_screen.dart';
import 'analysis/analysis_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  // Tabs will be integrated here
  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(onGoToWorkout: () => setState(() => _currentIndex = 2)),
      const ProgramsScreen(),
      const WorkoutPreviewScreen(),
      const AnalysisScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            // Handle Workout Start separately perhaps, or just navigate
            // For now, simple navigation
          }
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: AppStrings.dashboard,
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: AppStrings.programs,
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center),
            selectedIcon: Icon(Icons.fitness_center),
            label: AppStrings.workout,
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: AppStrings.analysis,
          ),
        ],
      ),
    );
  }
}
