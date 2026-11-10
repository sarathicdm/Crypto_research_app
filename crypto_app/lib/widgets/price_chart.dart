import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/chart_model.dart';

class PriceChart extends StatelessWidget {
  final ChartModel chart;
  final bool isPositive;

  const PriceChart({super.key, required this.chart, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    if (chart.points.isEmpty) {
      return const Center(
          child: Text('No chart data', style: TextStyle(color: AppTheme.textSecondary)));
    }

    final spots = chart.points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.price))
        .toList();

    final lineColor = isPositive ? AppTheme.positive : AppTheme.negative;
    final minY = chart.points.map((p) => p.price).reduce((a, b) => a < b ? a : b);
    final maxY = chart.points.map((p) => p.price).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.02;

    return LineChart(
      LineChartData(
        minY: minY - padding,
        maxY: maxY + padding,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppTheme.card,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '\$${s.y.toStringAsFixed(2)}',
                      const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [lineColor.withAlpha(60), lineColor.withAlpha(0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
