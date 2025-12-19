import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/program_provider.dart';
import 'routine_editor_screen.dart';

class ProgramDetailsScreen extends StatelessWidget {
  final String programId;

  const ProgramDetailsScreen({super.key, required this.programId});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgramProvider>(
      builder: (context, provider, child) {
        final programIndex = provider.programs.indexWhere(
          (p) => p.id == programId,
        );

        if (programIndex == -1) {
          return Scaffold(
            appBar: AppBar(title: const Text("Errore")),
            body: const Center(child: Text("Programma non trovato")),
          );
        }

        final program = provider.programs[programIndex];

        return Scaffold(
          appBar: AppBar(title: Text(program.name)),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: program.routines.length,
            itemBuilder: (context, index) {
              final routine = program.routines[index];
              return Card(
                child: ListTile(
                  title: Text(routine.name),
                  subtitle: Text("${routine.exercises.length} Esercizi"),
                  trailing: const Icon(Icons.edit),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoutineEditorScreen(
                          programId: program.id,
                          routine: routine,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
