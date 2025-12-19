import 'dart:async';
import 'package:flutter/material.dart';

class RecapScreen extends StatefulWidget {
  final String exerciseName;
  final void Function(BuildContext) onNext;
  final Map<String, dynamic> stats;
  final int restSeconds;

  const RecapScreen({
    super.key,
    required this.exerciseName,
    required this.onNext,
    required this.stats,
    this.restSeconds = 90, // Default rest if not passed
  });

  @override
  State<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends State<RecapScreen> {
  late Timer _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.restSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsLeft > 0) {
            _secondsLeft--;
          } else {
            _timer.cancel();
            _timer.cancel();
            widget.onNext(context); // Auto navigate
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                "Hai completato\n${widget.exerciseName}!",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              // Rest Timer Display
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _secondsLeft < 10 ? Colors.red : Colors.green,
                    ),
                  ),
                  child: Text(
                    "Recupero: ${_secondsLeft}s",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Stats Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  children: [
                    _buildStatRow(
                      Icons.fitness_center,
                      "Carico (${widget.stats['weightLabel']})",
                      widget.stats['weightDiff'] ?? "-",
                      Colors.blue,
                    ),
                    const Divider(color: Colors.grey, height: 32),
                    _buildStatRow(
                      Icons.repeat,
                      "Ripetizioni (${widget.stats['repsLabel']})",
                      widget.stats['repsDiff'] ?? "-",
                      Colors.orange,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: () {
                  _timer.cancel();
                  _timer.cancel();
                  widget.onNext(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text("PROSSIMO ESERCIZIO"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
