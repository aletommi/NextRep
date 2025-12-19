import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/program_provider.dart';

class ProgramCreationWizard extends StatefulWidget {
  const ProgramCreationWizard({super.key});

  @override
  State<ProgramCreationWizard> createState() => _ProgramCreationWizardState();
}

class _ProgramCreationWizardState extends State<ProgramCreationWizard> {
  final _nameController = TextEditingController();
  int _routineCount = 3;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nuova Scheda")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Nome Scheda (es. Massa 2025)",
                errorText: _errorText,
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
            ),
            const SizedBox(height: 20),
            const Text("Quante routine ha questa scheda?"),
            Slider(
              value: _routineCount.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              label: _routineCount.toString(),
              onChanged: (val) {
                setState(() => _routineCount = val.toInt());
              },
            ),
            Text(
              "Giornate: $_routineCount",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isEmpty) {
                  setState(() {
                    _errorText = "Inserisci un nome per la scheda";
                  });
                  return;
                }

                final provider = Provider.of<ProgramProvider>(
                  context,
                  listen: false,
                );
                provider.createProgram(_nameController.text, _routineCount);
                Navigator.pop(context);
              },
              child: const Text("Crea Scheda"),
            ),
          ],
        ),
      ),
    );
  }
}
