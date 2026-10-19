import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/utils/targets.dart';
import '../../models/exercise.dart';
import '../../models/routine.dart';
import '../../models/workout_session.dart';
import '../../providers/workout_session_provider.dart';
import '../../services/database_service.dart';
import 'widgets/workout_keypad.dart';
import 'recap_screen.dart';

/// One exercise at a time: tap the reps done, confirm the weight, rest,
/// repeat. After the last set of an exercise a recap is shown.
class LiveWorkoutScreen extends StatefulWidget {
  final Routine routine;

  const LiveWorkoutScreen({super.key, required this.routine});

  @override
  State<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends State<LiveWorkoutScreen> {
  static const int _confirmSeconds = 15;
  static const double _defaultWeight = 20.0;

  int _exerciseIndex = 0;

  // Weight confirmation after each set.
  bool _showWeightConfirmation = false;
  Timer? _confirmationTimer;
  int _confirmationCountdown = _confirmSeconds;
  double _pendingWeight = 0.0;
  double _suggestedWeight = 0.0;

  // Rest countdown between sets.
  Timer? _restTicker;

  RoutineExercise get _currentEx => widget.routine.exercises[_exerciseIndex];
  bool get _isLastExercise =>
      _exerciseIndex >= widget.routine.exercises.length - 1;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    WidgetsBinding.instance.addPostFrameCallback((_) => _activateExercise());
  }

  @override
  void dispose() {
    _confirmationTimer?.cancel();
    _restTicker?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  Exercise? _exerciseOf(RoutineExercise rx) =>
      context.read<DatabaseService>().getExercise(rx.exerciseId);

  String _nameOf(RoutineExercise rx) => _exerciseOf(rx)?.name ?? 'Esercizio';

  void _activateExercise() {
    final exercise = _exerciseOf(_currentEx);
    if (exercise == null) return;
    context.read<WorkoutSessionProvider>().setActiveExercise(exercise);
  }

  // --- Logging a set ---

  Future<void> _onRepSelected(int reps) async {
    final sessions = context.read<WorkoutSessionProvider>();
    final rx = _currentEx;
    final targetSets = int.tryParse(rx.sets) ?? 3;
    final setIndex = sessions.activeExercise?.sets.length ?? 0;

    final suggested =
        parseWeight(targetForSet(rx.weight, setIndex)) ??
        await sessions.getSuggestedWeight(_nameOf(rx), setIndex) ??
        _defaultWeight;
    if (!mounted) return;

    _pendingWeight = suggested;
    _suggestedWeight = suggested;
    await sessions.addSet(reps, suggested);
    if (!mounted) return;

    final completedSets = sessions.activeExercise?.sets.length ?? 0;
    if (completedSets >= targetSets) {
      await _showRecap();
    } else {
      _startConfirmation();
      _startRestTicker();
    }
  }

  Future<void> _showRecap() async {
    final sessions = context.read<WorkoutSessionProvider>();
    final rx = _currentEx;
    final name = _nameOf(rx);
    final stats = sessions.getExerciseStats(name, rx);
    final isLast = _isLastExercise;

    sessions.stopRestTimer();
    _restTicker?.cancel();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => RecapScreen(
          exerciseName: name,
          stats: stats,
          restSeconds: rx.restTimeSeconds ?? 90,
          isLastExercise: isLast,
          onNext: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
    if (!mounted) return;

    if (isLast) {
      Navigator.of(context).pop();
    } else {
      setState(() => _exerciseIndex++);
      _activateExercise();
    }
  }

  // --- Weight confirmation ---

  void _startConfirmation() {
    setState(() {
      _showWeightConfirmation = true;
      _confirmationCountdown = _confirmSeconds;
    });
    _confirmationTimer?.cancel();
    _confirmationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_confirmationCountdown > 1) {
        setState(() => _confirmationCountdown--);
      } else {
        _confirmWeight();
      }
    });
  }

  Future<void> _confirmWeight() async {
    _confirmationTimer?.cancel();
    if (_pendingWeight != _suggestedWeight) {
      await context.read<WorkoutSessionProvider>().updateLastSetWeight(
        _pendingWeight,
      );
    }
    if (mounted) setState(() => _showWeightConfirmation = false);
  }

  void _changeWeight(double delta) {
    _confirmationTimer?.cancel(); // user is interacting: no auto-confirm
    setState(() {
      _pendingWeight = (_pendingWeight + delta).clamp(0, 1000);
    });
  }

  // --- Rest ---

  int get _restSeconds => _currentEx.restTimeSeconds ?? 90;

  void _startRestTicker() {
    _restTicker?.cancel();
    _restTicker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      final sessions = context.read<WorkoutSessionProvider>();
      final start = sessions.restStartTime;
      if (start == null) {
        _restTicker?.cancel();
        return;
      }
      final elapsed = DateTime.now().difference(start).inSeconds;
      if (elapsed >= _restSeconds && !_showWeightConfirmation) {
        _skipRest();
      } else {
        setState(() {});
      }
    });
  }

  void _skipRest() {
    _restTicker?.cancel();
    context.read<WorkoutSessionProvider>().stopRestTimer();
  }

  // --- Exit ---

  Future<bool> _confirmExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminare allenamento?'),
        content: const Text('Le serie già registrate verranno salvate.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Termina'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _finishWorkout() async {
    if (await _confirmExit() && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<WorkoutSessionProvider>();
    final rx = _currentEx;
    final exercise = _exerciseOf(rx);
    final nextRx = _isLastExercise
        ? null
        : widget.routine.exercises[_exerciseIndex + 1];

    final setIndex = sessions.activeExercise?.sets.length ?? 0;
    final targetReps = targetForSet(rx.reps, setIndex);
    final targetWeight = targetForSet(rx.weight, setIndex);

    final isResting = sessions.isTimerRunning;
    final restStart = sessions.restStartTime;
    final restLeft = restStart == null
        ? 0
        : (_restSeconds - DateTime.now().difference(restStart).inSeconds).clamp(
            0,
            _restSeconds,
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmExit() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 48),
                            Text(
                              (exercise?.muscleGroup ?? '').toUpperCase(),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: _finishWorkout,
                            ),
                          ],
                        ),
                        Text(
                          'Esercizio ${_exerciseIndex + 1} di '
                          '${widget.routine.exercises.length}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exercise?.name ?? 'Esercizio',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Serie ${setIndex + 1} di ${rx.sets} · '
                            'Target: $targetReps reps'
                            '${targetWeight.isNotEmpty ? ' · $targetWeight kg' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (rx.notes != null && rx.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              rx.notes!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (nextRx != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Prossimo: ${_nameOf(nextRx)}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  _SetsDone(sets: sessions.activeExercise?.sets ?? const []),
                  const SizedBox(height: 16),
                  const Text(
                    'Ripetizioni fatte?',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: WorkoutKeypad(onRepSelected: _onRepSelected),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            if (isResting || _showWeightConfirmation)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.95),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'RECUPERO',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${restLeft}s',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (_showWeightConfirmation)
                        _buildWeightConfirmation(context)
                      else
                        ElevatedButton(
                          onPressed: _skipRest,
                          child: const Text('SALTA RECUPERO'),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightConfirmation(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: _confirmationCountdown / _confirmSeconds,
            backgroundColor: Colors.grey[800],
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Carico usato:',
            style: TextStyle(fontSize: 16, color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: () => _changeWeight(-2.5),
                icon: const Icon(Icons.remove),
                style: IconButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
              const SizedBox(width: 24),
              Text(
                '${_formatWeight(_pendingWeight)} kg',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 24),
              IconButton.filledTonal(
                onPressed: () => _changeWeight(2.5),
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ],
          ),
          if (_suggestedWeight != _pendingWeight)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '(Suggerito: ${_formatWeight(_suggestedWeight)} kg)',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmWeight,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('CONFERMA'),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatWeight(double w) =>
      w == w.roundToDouble() ? w.toStringAsFixed(0) : w.toStringAsFixed(1);
}

/// Compact list of the sets already logged for the current exercise.
class _SetsDone extends StatelessWidget {
  final List<WorkoutSet> sets;

  const _SetsDone({required this.sets});

  @override
  Widget build(BuildContext context) {
    if (sets.isEmpty) return const SizedBox(height: 24);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final s in sets)
          Chip(
            label: Text(
              '${s.reps} x ${_LiveWorkoutScreenState._formatWeight(s.weight ?? 0)} kg',
            ),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}
