import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class ProgressChart extends StatelessWidget {
  const ProgressChart({super.key});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 100),
              const FlSpot(1, 102.5),
              const FlSpot(2, 105),
              const FlSpot(3, 105),
              const FlSpot(4, 110),
            ],
            isCurved: true,
            color: AppColors.secondary,
            barWidth: 4,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              color: AppColors.secondary.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}
