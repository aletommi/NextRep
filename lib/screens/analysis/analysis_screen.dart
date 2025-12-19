import 'package:flutter/material.dart';
import 'widgets/progress_chart.dart';
import 'widgets/muscle_heatmap.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analisi & Profilo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            "Force Progression",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          SizedBox(height: 200, child: ProgressChart()),

          SizedBox(height: 32),
          Text(
            "Muscle Heatmap",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          MuscleHeatmap(),

          SizedBox(height: 32),
          Text(
            "Body Measurements",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ListTile(
            title: Text("Peso Corporeo"),
            trailing: Text("75.5 kg"),
            leading: Icon(Icons.monitor_weight),
          ),
          ListTile(
            title: Text("Giro Vita"),
            trailing: Text("80 cm"),
            leading: Icon(Icons.accessibility),
          ),
        ],
      ),
    );
  }
}
