import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/health_record_model.dart';
import '../../../providers/health_provider.dart';
import '../../../providers/medicine_provider.dart';
import '../../widgets/stat_card.dart';

class HealthAnalyticsScreen extends StatefulWidget {
  const HealthAnalyticsScreen({super.key});

  @override
  State<HealthAnalyticsScreen> createState() => _HealthAnalyticsScreenState();
}

class _HealthAnalyticsScreenState extends State<HealthAnalyticsScreen> {
  String _selectedMetric = 'blood_pressure';
  HealthTimeRange _selectedRange = HealthTimeRange.weekly;

  final List<Map<String, dynamic>> _metrics = [
    {'id': 'blood_pressure', 'name': 'Blood Pressure', 'unit': 'mmHg'},
    {'id': 'blood_glucose', 'name': 'Blood Glucose', 'unit': 'mg/dL'},
    {'id': 'heart_rate', 'name': 'Heart Rate', 'unit': 'bpm'},
    {'id': 'body_temperature', 'name': 'Temperature', 'unit': '°C'},
    {'id': 'weight', 'name': 'Weight', 'unit': 'kg'},
    {'id': 'adherence', 'name': 'Med Adherence', 'unit': '%'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final healthProvider = Provider.of<HealthProvider>(context);
    final medProvider = Provider.of<MedicineProvider>(context);

    final isAdherence = _selectedMetric == 'adherence';
    final stats = !isAdherence
        ? healthProvider.calculateStats(overrideType: _selectedMetric, overrideRange: _selectedRange)
        : null;

    final records = !isAdherence
        ? healthProvider.getFilteredRecords(overrideType: _selectedMetric, overrideRange: _selectedRange)
        : <HealthRecordModel>[];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Health Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Range Segmented Selector
            Center(
              child: SegmentedButton<HealthTimeRange>(
                segments: const [
                  ButtonSegment(value: HealthTimeRange.daily, label: Text('Today')),
                  ButtonSegment(value: HealthTimeRange.weekly, label: Text('7 Days')),
                  ButtonSegment(value: HealthTimeRange.monthly, label: Text('30 Days')),
                  ButtonSegment(value: HealthTimeRange.all, label: Text('All')),
                ],
                selected: {_selectedRange},
                onSelectionChanged: (set) => setState(() => _selectedRange = set.first),
              ),
            ),
            const SizedBox(height: 16),

            // Horizontal Metric Selection Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _metrics.map((m) {
                  final isSelected = _selectedMetric == m['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(m['name']),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedMetric = m['id']),
                      selectedColor: AppColors.primary.withValues(alpha: 0.18),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppColors.primary : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            // Chart Card
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getMetricTitle(_selectedMetric),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (!isAdherence)
                          Text(
                            'Unit: ${_getUnit(_selectedMetric)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 220,
                      child: isAdherence
                          ? _buildAdherenceChart(medProvider, isDark)
                          : _buildVitalsLineChart(records, isDark),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Statistical Analytics Overview
            const Text(
              'Statistical Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),

            if (isAdherence) ...[
              Builder(
                builder: (context) {
                  final overallAdherence = medProvider.calculateAdherence();
                  final history = medProvider.history;
                  final taken = history.where((h) => h.isTaken).length;
                  final skipped = history.where((h) => h.isSkipped).length;
                  final missed = history.where((h) => h.isMissed).length;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Adherence Rate',
                              value: '${overallAdherence.toStringAsFixed(1)}%',
                              subtitle: 'Overall consistency',
                              icon: Icons.verified_rounded,
                              iconColor: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              title: 'Taken Doses',
                              value: '$taken',
                              subtitle: '$missed missed, $skipped skipped',
                              icon: Icons.check_circle_rounded,
                              iconColor: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ] else if (stats != null) ...[
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Average',
                      value: _selectedMetric == 'blood_pressure' && stats.secondaryAverage != null
                          ? '${stats.average.toInt()}/${stats.secondaryAverage!.toInt()}'
                          : stats.average.toStringAsFixed(1),
                      subtitle: 'Selected period avg',
                      icon: Icons.functions_rounded,
                      iconColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Range (Min - Max)',
                      value: _selectedMetric == 'blood_pressure'
                          ? '${stats.min.toInt()} - ${stats.max.toInt()}'
                          : '${stats.min.toStringAsFixed(1)} - ${stats.max.toStringAsFixed(1)}',
                      subtitle: stats.trendSummary,
                      icon: Icons.swap_vert_rounded,
                      iconColor: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.insights_rounded, color: AppColors.primary, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Trend Analysis',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${stats.trendSummary} across ${stats.count} recorded entries in this timeframe.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsLineChart(List<HealthRecordModel> records, bool isDark) {
    if (records.isEmpty) {
      return const Center(
        child: Text('No data points recorded for this metric & range.'),
      );
    }

    final List<FlSpot> spotsPrimary = [];
    final List<FlSpot> spotsSecondary = [];

    for (int i = 0; i < records.length; i++) {
      spotsPrimary.add(FlSpot(i.toDouble(), records[i].valuePrimary));
      if (records[i].valueSecondary != null) {
        spotsSecondary.add(FlSpot(i.toDouble(), records[i].valueSecondary!));
      }
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 38),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < records.length) {
                  final dt = DateTime.tryParse(records[idx].recordedAt);
                  if (dt != null) {
                    return Text(
                      DateFormat('MM/dd').format(dt),
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spotsPrimary,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          if (spotsSecondary.isNotEmpty)
            LineChartBarData(
              spots: spotsSecondary,
              isCurved: true,
              color: AppColors.secondary,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.secondary.withValues(alpha: 0.12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdherenceChart(MedicineProvider medProvider, bool isDark) {
    final history = medProvider.history;
    if (history.isEmpty) {
      return const Center(child: Text('No medication history logged yet.'));
    }

    final taken = history.where((h) => h.isTaken).length.toDouble();
    final skipped = history.where((h) => h.isSkipped).length.toDouble();
    final missed = history.where((h) => h.isMissed).length.toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (taken + skipped + missed + 2).clamp(5.0, 100.0),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [
            BarChartRodData(toY: taken, color: AppColors.success, width: 22, borderRadius: BorderRadius.circular(6))
          ]),
          BarChartGroupData(x: 1, barRods: [
            BarChartRodData(toY: skipped, color: AppColors.warning, width: 22, borderRadius: BorderRadius.circular(6))
          ]),
          BarChartGroupData(x: 2, barRods: [
            BarChartRodData(toY: missed, color: AppColors.danger, width: 22, borderRadius: BorderRadius.circular(6))
          ]),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                switch (val.toInt()) {
                  case 0:
                    return const Text('Taken', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11));
                  case 1:
                    return const Text('Skipped', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11));
                  case 2:
                    return const Text('Missed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11));
                  default:
                    return const SizedBox.shrink();
                }
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  String _getMetricTitle(String id) {
    switch (id) {
      case 'blood_pressure':
        return 'Blood Pressure (Systolic & Diastolic)';
      case 'blood_glucose':
        return 'Blood Glucose Trends';
      case 'heart_rate':
        return 'Heart Rate Trends';
      case 'body_temperature':
        return 'Body Temperature Trends';
      case 'weight':
        return 'Body Weight Trends';
      case 'adherence':
        return 'Medicine Adherence Distribution';
      default:
        return 'Metric Graph';
    }
  }

  String _getUnit(String id) {
    switch (id) {
      case 'blood_pressure':
        return 'mmHg';
      case 'blood_glucose':
        return 'mg/dL';
      case 'heart_rate':
        return 'bpm';
      case 'body_temperature':
        return '°C';
      case 'weight':
        return 'kg';
      default:
        return '';
    }
  }
}
