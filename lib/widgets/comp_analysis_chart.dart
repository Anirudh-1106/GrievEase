import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ComplaintAnalyticsChart extends StatelessWidget {
  final Map<String, int> complaintStats = const {
    'Academics': 5,
    'Infrastructure': 8,
    'Faculty': 3,
    'Hostel': 4,
  };

  const ComplaintAnalyticsChart({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: BarChart(
        BarChartData(
          barGroups: complaintStats.entries.map((entry) {
            return BarChartGroupData(
              x: complaintStats.keys.toList().indexOf(entry.key),
              barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  color: Colors.deepPurple,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final categories = complaintStats.keys.toList();
                  return Text(
                    categories[value.toInt()],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(color: Colors.black),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
