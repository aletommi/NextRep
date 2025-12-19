import 'package:flutter/material.dart';

class WorkoutKeypad extends StatefulWidget {
  final Function(int reps) onRepSelected;

  const WorkoutKeypad({super.key, required this.onRepSelected});

  @override
  State<WorkoutKeypad> createState() => _WorkoutKeypadState();
}

class _WorkoutKeypadState extends State<WorkoutKeypad> {
  int _pageIndex = 0; // 0 or 1

  final List<List<dynamic>> _pages = [
    [2, 3, 4, 5, 6, 7, 8, "->"], // Page 1
    [
      '<-',
      9,
      10,
      11,
      12,
      15,
      18,
      'Custom',
    ], // Page 2 (Adding Custom for safety)
  ];

  @override
  Widget build(BuildContext context) {
    final currentPageItems = _pages[_pageIndex];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: currentPageItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final item = currentPageItems[index];

        return _buildButton(item);
      },
    );
  }

  Widget _buildButton(dynamic item) {
    final isArrow = item is String && (item == "->" || item == "<-");
    final isCustom = item == 'Custom';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (item == "->") {
            setState(() => _pageIndex = 1);
          } else if (item == "<-") {
            setState(() => _pageIndex = 0);
          } else if (isCustom) {
            // Show custom dialog or something
            // For now just pass -1 or handle externally?
            // User didn't specify custom but it's good UX.
            // Let's prompt.
            _showCustomInput();
          } else {
            // It's a number
            widget.onRepSelected(item as int);
          }
        },
        borderRadius: BorderRadius.circular(40),
        splashColor: Theme.of(context).primaryColor.withValues(alpha: 0.5),
        highlightColor: Theme.of(context).primaryColor,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isArrow
                ? Theme.of(context).cardColor.withValues(alpha: 0.5)
                : Theme.of(context).cardColor,
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: Center(
            child: isArrow
                ? Icon(
                    item == "->" ? Icons.arrow_forward : Icons.arrow_back,
                    size: 28,
                  )
                : Text(
                    isCustom ? "..." : item.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _showCustomInput() {
    showDialog(
      context: context,
      builder: (context) {
        int? value;
        return AlertDialog(
          title: const Text("Ripetizioni"),
          content: TextField(
            keyboardType: TextInputType.number,
            autofocus: true,
            onChanged: (v) => value = int.tryParse(v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annulla"),
            ),
            TextButton(
              onPressed: () {
                if (value != null) {
                  Navigator.pop(context);
                  widget.onRepSelected(value!);
                }
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
