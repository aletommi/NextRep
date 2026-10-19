import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/program_provider.dart';
import 'program_creation_wizard.dart';
import 'program_details_screen.dart';

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgramProvider>();
    final programs = provider.programs;

    return Scaffold(
      appBar: AppBar(title: const Text('Le tue Schede')),
      body: programs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Nessuna scheda trovata.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _navigateToWizard(context),
                    child: const Text('Crea Nuova Scheda'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
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
                      backgroundColor: isActive ? Colors.green : Colors.grey,
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
                      '${program.routines.length} routine'
                      '${isActive ? ' · attiva' : ''}',
                    ),
                    trailing: Switch(
                      value: isActive,
                      onChanged: isActive
                          ? null
                          : (_) => provider.setActiveProgram(program.id),
                    ),
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
  }

  void _navigateToWizard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProgramCreationWizard()),
    );
  }
}
