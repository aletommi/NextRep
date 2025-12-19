import 'package:flutter/material.dart';
import 'dart:async';

class RestTimer {
  static void show(BuildContext context) {
    showBottomSheet(
      context: context,
      builder: (ctx) => const RestTimerWidget(),
    );
  }
}

class RestTimerWidget extends StatefulWidget {
  const RestTimerWidget({super.key});

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget> {
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_seconds / 60).floor();
    final s = _seconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "REST",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                _formattedTime,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close bottom sheet
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("SKIP"),
          ),
        ],
      ),
    );
  }
}
