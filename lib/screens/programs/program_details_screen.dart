import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/program_provider.dart';
import 'routine_editor_screen.dart';

class ProgramDetailsScreen extends StatelessWidget {
  final String programId;

  const ProgramDetailsScreen({super.key, required this.programId});

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare la scheda?'),
        content: const Text(
          'Le routine e gli esercizi della scheda andranno persi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<ProgramProvider>().deleteProgram(programId);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgramProvider>();
    final program = provider.programs
        .where((p) => p.id == programId)
        .firstOrNull;

    if (program == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Scheda non trovata')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(program.name),
        actions: [
          if (!program.isActive)
            TextButton(
              onPressed: () => provider.setActiveProgram(program.id),
              child: const Text('Attiva'),
            ),
          IconButton(
            tooltip: 'Elimina scheda',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: program.routines.length,
        itemBuilder: (context, index) {
          final routine = program.routines[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(routine.name),
              subtitle: Text('${routine.exercises.length} esercizi'),
              trailing: const Icon(Icons.chevron_right),
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
  }
}
