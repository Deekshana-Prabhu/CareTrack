import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/medicine_model.dart';
import '../../../models/medicine_schedule_model.dart';
import '../../../providers/medicine_provider.dart';
import '../../widgets/status_badge.dart';

class MedicineCalendarScreen extends StatefulWidget {
  const MedicineCalendarScreen({super.key});

  @override
  State<MedicineCalendarScreen> createState() => _MedicineCalendarScreenState();
}

class _MedicineCalendarScreenState extends State<MedicineCalendarScreen> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final medProvider = Provider.of<MedicineProvider>(context);

    final daySchedules = medProvider.getScheduleForDate(_selectedDate);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Medicine Calendar'),
      ),
      body: Column(
        children: [
          // Month Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _prevMonth,
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_focusedMonth),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // Days of Week Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map((d) => SizedBox(
                        width: 40,
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Monthly Calendar Grid
          Container(
            color: isDark ? AppColors.darkSurface : Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: _buildCalendarGrid(),
          ),

          const Divider(height: 1),

          // Day Schedule Title
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Schedule: ${DateFormat('EEEE, MMM d').format(_selectedDate)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${daySchedules.length} items',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Schedule List for Selected Date
          Expanded(
            child: daySchedules.isEmpty
                ? Center(
                    child: Text(
                      'No medicines scheduled for this date.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: daySchedules.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final item = daySchedules[idx];
                      final MedicineModel med = item['medicine'];
                      final MedicineScheduleModel sched = item['schedule'];
                      final String status = item['status'];
                      final String time = item['time'];

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.medication_rounded, size: 20, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        Text(
                                          '${med.dosage} • ${med.foodTiming}',
                                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        AppDateUtils.formatTimeString(time),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      StatusBadge.forMedicineStatus(status),
                                    ],
                                  ),
                                ],
                              ),
                              if (status != 'taken' && status != 'skipped') ...[
                                const Divider(height: 18),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () => medProvider.markDoseSkipped(medicine: med, schedule: sched),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        side: const BorderSide(color: AppColors.warning),
                                        foregroundColor: AppColors.warning,
                                      ),
                                      child: const Text('Skip'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final smsResult = await medProvider.markDoseTaken(medicine: med, schedule: sched);
                                        if (context.mounted) {
                                          final msg = smsResult != null ? smsResult.message : 'Dose recorded as Taken!';
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(msg),
                                              backgroundColor: AppColors.success,
                                              duration: const Duration(seconds: 4),
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      ),
                                      child: const Text('Take'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    final totalSlots = ((startWeekday + daysInMonth + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalSlots,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final dayNumber = index - startWeekday + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
        final isSelected = AppDateUtils.isSameDay(cellDate, _selectedDate);
        final isToday = AppDateUtils.isSameDay(cellDate, DateTime.now());

        return InkWell(
          onTap: () => setState(() => _selectedDate = cellDate),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : isToday
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isToday && !isSelected
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
            ),
            child: Center(
              child: Text(
                '$dayNumber',
                style: TextStyle(
                  fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : isToday
                          ? AppColors.primary
                          : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
