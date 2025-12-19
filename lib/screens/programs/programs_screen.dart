import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/program_provider.dart';
// import 'routine_builder_screen.dart'; // Deprecated/Refactor
import 'program_creation_wizard.dart';
import 'program_details_screen.dart';

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure ProgramProvider is provided in main.dart (It will be, I need to check main.dart later)
    // For now assuming it is or will be.
    // If ProgramProvider is not at root, I might need to add it.

    return Consumer<ProgramProvider>(
      builder: (context, provider, child) {
        final programs = provider.programs;

        return Scaffold(
          appBar: AppBar(title: const Text('Le tue Schede')),
          body: programs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Nessuna scheda trovata."),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _navigateToWizard(context),
                        child: const Text("Crea Nuova Scheda"),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: programs.length,
                  itemBuilder: (context, index) {
                    final program = programs[index];
                    final isActive = program.isActive;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive
                              ? Colors.green
                              : Colors.grey,
                          child: Icon(
                            isActive ? Icons.check : Icons.fitness_center,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          program.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "${program.routines.length} Giornate (Routine)",
                        ),
                        trailing: programs.length > 1
                            ? Switch(
                                value: isActive,
                                onChanged: (val) {
                                  if (val) {
                                    provider.setActiveProgram(program.id);
                                  }
                                },
                              )
                            : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProgramDetailsScreen(programId: program.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _navigateToWizard(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _navigateToWizard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProgramCreationWizard()),
    );
  }
}
