import 'dart:async';
import 'package:flutter/material.dart';
import '../../providers/workout_session_provider.dart';

/// Shown after the last set of an exercise: summary vs target plus the rest
/// countdown before moving to the next exercise.
class RecapScreen extends StatefulWidget {
  final String exerciseName;
  final ExerciseStats stats;
  final int restSeconds;
  final bool isLastExercise;
  final VoidCallback onNext;

  const RecapScreen({
    super.key,
    required this.exerciseName,
    required this.stats,
    required this.restSeconds,
    required this.isLastExercise,
    required this.onNext,
  });

  @override
  State<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends State<RecapScreen> {
  Timer? _timer;
  late int _secondsLeft;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.restSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        _timer?.cancel();
        setState(() => _secondsLeft = 0);
        // Rest is over: move on automatically (the last exercise waits for
        // the user to tap "Termina").
        if (!widget.isLastExercise) widget.onNext();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _next() {
    _timer?.cancel();
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final change = stats.percentChange;

    String targetLabel;
    Color targetColor;
    if (change == null) {
      targetLabel = 'Nessun carico target nella scheda';
      targetColor = Colors.grey;
    } else if (change.abs() < 0.05) {
      targetLabel = 'Target raggiunto';
      targetColor = Colors.green;
    } else if (change > 0) {
      targetLabel = '+${change.toStringAsFixed(1)}% rispetto al target';
      targetColor = Colors.green;
    } else {
      targetLabel = '${change.toStringAsFixed(1)}% rispetto al target';
      targetColor = Colors.orange;
    }

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
                'Hai completato\n${widget.exerciseName}!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              if (!widget.isLastExercise)
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
                      _secondsLeft > 0
                          ? 'Recupero: ${_secondsLeft}s'
                          : 'Recupero finito!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  children: [
                    _StatRow(
                      icon: Icons.fitness_center,
                      label: 'Volume (kg x reps)',
                      value: stats.volume.toStringAsFixed(0),
                      color: Colors.blue,
                    ),
                    const Divider(color: Colors.grey, height: 32),
                    _StatRow(
                      icon: Icons.flag_outlined,
                      label: stats.targetVolume == null
                          ? 'Target'
                          : 'Target ${stats.targetVolume!.toStringAsFixed(0)}',
                      value: targetLabel,
                      color: targetColor,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text(
                  widget.isLastExercise
                      ? 'TERMINA ALLENAMENTO'
                      : 'PROSSIMO ESERCIZIO',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
