import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/health_reference.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/health_record_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/health_provider.dart';
import 'add_health_record_screen.dart';
import 'health_analytics_screen.dart';
import '../../widgets/stat_card.dart';

class HealthMonitoringScreen extends StatefulWidget {
  const HealthMonitoringScreen({super.key});

  @override
  State<HealthMonitoringScreen> createState() => _HealthMonitoringScreenState();
}

class _HealthMonitoringScreenState extends State<HealthMonitoringScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _metricTypes = [
    'blood_pressure',
    'blood_glucose',
    'heart_rate',
    'body_temperature',
    'oxygen_saturation',
    'weight',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _metricTypes.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _deleteRecord(BuildContext context, HealthRecordModel record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Health Record'),
        content: Text('Are you sure you want to delete this ${record.displayName} record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final health = Provider.of<HealthProvider>(context, listen: false);
      await health.deleteRecord(record);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record deleted'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final health = Provider.of<HealthProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Health Monitoring'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_rounded),
            tooltip: 'Health Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HealthAnalyticsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Metric',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddHealthRecordScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Blood Pressure'),
            Tab(text: 'Blood Glucose'),
            Tab(text: 'Heart Rate'),
            Tab(text: 'Body Temp'),
            Tab(text: 'Oxygen (SpO2)'),
            Tab(text: 'Weight'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (user?.id != null) {
            await health.loadHealthData(user!.id!);
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: _metricTypes.map((type) => _buildMetricView(type, isDark)).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final currentType = _metricTypes[_tabController.index];
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddHealthRecordScreen(initialType: currentType)),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildMetricView(String type, bool isDark) {
    final health = Provider.of<HealthProvider>(context);
    final records = health.records.where((r) => r.recordType == type).toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    final latest = records.isNotEmpty ? records.first : null;
    final stats = health.calculateStats(overrideType: type, overrideRange: HealthTimeRange.all);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Latest Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Latest Reading',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      if (latest != null)
                        Text(
                          AppDateUtils.formatDateTime(DateTime.parse(latest.recordedAt)),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        latest != null ? latest.formattedValue : 'No records yet',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      if (latest != null) _buildEvaluationBadge(latest),
                    ],
                  ),
                  if (latest?.notes != null && latest!.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Note: ${latest.notes}',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Statistics Row
          if (records.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Average',
                    value: type == 'blood_pressure' && stats.secondaryAverage != null
                        ? '${stats.average.toInt()}/${stats.secondaryAverage!.toInt()}'
                        : stats.average.toStringAsFixed(1),
                    subtitle: 'All time',
                    icon: Icons.calculate_rounded,
                    iconColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Min / Max',
                    value: type == 'blood_pressure'
                        ? '${stats.min.toInt()} / ${stats.max.toInt()}'
                        : '${stats.min.toStringAsFixed(1)} / ${stats.max.toStringAsFixed(1)}',
                    subtitle: stats.trendSummary,
                    icon: Icons.trending_up_rounded,
                    iconColor: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // History Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Historical Logs (${records.length})',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HealthAnalyticsScreen()),
                  );
                },
                child: const Text('View Charts'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (records.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.monitor_heart_outlined, size: 48, color: isDark ? AppColors.darkTextSecondary : const Color(0xFFCBD5E1)),
                      const SizedBox(height: 12),
                      const Text('No records logged yet', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Tap the "+" button below to log your reading',
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final rec = records[index];
                final dt = DateTime.tryParse(rec.recordedAt) ?? DateTime.now();

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          rec.formattedValue,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        _buildEvaluationBadge(rec),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          AppDateUtils.formatDateTime(dt),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        if (rec.mealContext != null)
                          Text(
                            'Context: ${rec.mealContext}',
                            style: const TextStyle(fontSize: 11, color: AppColors.primary),
                          ),
                        if (rec.notes != null && rec.notes!.isNotEmpty)
                          Text(
                            'Note: ${rec.notes}',
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AddHealthRecordScreen(record: rec)),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                          onPressed: () => _deleteRecord(context, rec),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEvaluationBadge(HealthRecordModel rec) {
    HealthRangeResult? res;
    if (rec.recordType == 'blood_pressure' && rec.valueSecondary != null) {
      res = HealthReference.evaluateBloodPressure(rec.valuePrimary, rec.valueSecondary!);
    } else if (rec.recordType == 'blood_glucose') {
      res = HealthReference.evaluateBloodGlucose(rec.valuePrimary, context: rec.mealContext ?? 'Fasting');
    } else if (rec.recordType == 'heart_rate') {
      res = HealthReference.evaluateHeartRate(rec.valuePrimary);
    } else if (rec.recordType == 'body_temperature') {
      res = HealthReference.evaluateBodyTemperature(rec.valuePrimary);
    } else if (rec.recordType == 'oxygen_saturation') {
      res = HealthReference.evaluateSpO2(rec.valuePrimary);
    }

    if (res == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: res.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: res.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        res.status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: res.color),
      ),
    );
  }
}
