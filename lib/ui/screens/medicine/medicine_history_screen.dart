import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/medicine_history_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/medicine_provider.dart';
import '../../widgets/status_badge.dart';

class MedicineHistoryScreen extends StatefulWidget {
  const MedicineHistoryScreen({super.key});

  @override
  State<MedicineHistoryScreen> createState() => _MedicineHistoryScreenState();
}

class _MedicineHistoryScreenState extends State<MedicineHistoryScreen> {
  String _selectedRange = 'Weekly'; // Daily, Weekly, Monthly, All
  String _statusFilter = 'All'; // All, Taken, Skipped, Missed

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final med = Provider.of<MedicineProvider>(context, listen: false);
    final userId = auth.currentUser?.id;
    if (userId != null) {
      DateTime? start;
      final now = DateTime.now();
      if (_selectedRange == 'Daily') {
        start = DateTime(now.year, now.month, now.day);
      } else if (_selectedRange == 'Weekly') {
        start = now.subtract(const Duration(days: 7));
      } else if (_selectedRange == 'Monthly') {
        start = now.subtract(const Duration(days: 30));
      }

      final status = _statusFilter == 'All' ? null : _statusFilter.toLowerCase();
      await med.loadHistory(userId, start: start, status: status);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final medProvider = Provider.of<MedicineProvider>(context);
    final history = medProvider.history;

    final takenCount = history.where((h) => h.isTaken).length;
    final skippedCount = history.where((h) => h.isSkipped).length;
    final missedCount = history.where((h) => h.isMissed).length;
    final adherence = medProvider.calculateAdherence();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Medicine History'),
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Time Range Selector
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Daily', label: Text('Today')),
                        ButtonSegment(value: 'Weekly', label: Text('7 Days')),
                        ButtonSegment(value: 'Monthly', label: Text('30 Days')),
                        ButtonSegment(value: 'All', label: Text('All')),
                      ],
                      selected: {_selectedRange},
                      onSelectionChanged: (set) {
                        setState(() => _selectedRange = set.first);
                        _loadData();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip('All', _statusFilter == 'All', () {
                        setState(() => _statusFilter = 'All');
                        _loadData();
                      }),
                      const SizedBox(width: 8),
                      _buildChip('Taken ($takenCount)', _statusFilter == 'Taken', () {
                        setState(() => _statusFilter = 'Taken');
                        _loadData();
                      }, color: AppColors.success),
                      const SizedBox(width: 8),
                      _buildChip('Skipped ($skippedCount)', _statusFilter == 'Skipped', () {
                        setState(() => _statusFilter = 'Skipped');
                        _loadData();
                      }, color: AppColors.warning),
                      const SizedBox(width: 8),
                      _buildChip('Missed ($missedCount)', _statusFilter == 'Missed', () {
                        setState(() => _statusFilter = 'Missed');
                        _loadData();
                      }, color: AppColors.danger),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Adherence Rate Summary Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppColors.primary.withValues(alpha: 0.08),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Overall Adherence:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
                Text(
                  '${adherence.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                ),
              ],
            ),
          ),

          // History List
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_toggle_off_rounded,
                          size: 56,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFFCBD5E1),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No history records found',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Dose logs and reminders will appear here',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return _buildHistoryCard(item, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap, {Color color = AppColors.primary}) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: color.withValues(alpha: 0.18),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? color : null,
      ),
    );
  }

  Widget _buildHistoryCard(MedicineHistoryModel item, bool isDark) {
    final schedTime = DateTime.tryParse(item.scheduledTime);
    final actTime = item.actualTime != null ? DateTime.tryParse(item.actualTime!) : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getStatusColor(item.status).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_getStatusIcon(item.status), color: _getStatusColor(item.status), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.medicineName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      StatusBadge.forMedicineStatus(item.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dosage: ${item.dosage}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scheduled: ${schedTime != null ? AppDateUtils.formatDateTime(schedTime) : item.scheduledTime}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  if (actTime != null)
                    Text(
                      'Recorded: ${AppDateUtils.formatDateTime(actTime)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (item.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Note: ${item.notes}',
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
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'taken':
        return AppColors.success;
      case 'skipped':
        return AppColors.warning;
      case 'missed':
        return AppColors.danger;
      default:
        return AppColors.info;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'taken':
        return Icons.check_circle_rounded;
      case 'skipped':
        return Icons.skip_next_rounded;
      case 'missed':
        return Icons.cancel_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }
}
