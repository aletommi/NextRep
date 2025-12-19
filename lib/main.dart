import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'services/database_service.dart';
import 'screens/main_scaffold.dart';
import 'providers/workout_provider.dart';
import 'providers/program_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/workout_session_provider.dart';
import 'screens/auth/register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final databaseService = DatabaseService();
  await databaseService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: databaseService),
        ChangeNotifierProvider(create: (_) => WorkoutProvider(databaseService)),
        // Duplicate removed
        ChangeNotifierProvider(create: (_) => ProgramProvider(databaseService)),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => WorkoutSessionProvider(databaseService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NextRep',
      theme: AppTheme.darkTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          if (!auth.isAuthenticated) {
            return const RegisterScreen(); // Default to Register as requested
          }
          return const MainScaffold();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
