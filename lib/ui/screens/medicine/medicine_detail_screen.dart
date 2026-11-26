import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/medicine_model.dart';
import '../../../providers/medicine_provider.dart';
import 'add_edit_medicine_screen.dart';
import '../../widgets/status_badge.dart';

class MedicineDetailScreen extends StatelessWidget {
  final MedicineModel medicine;
  const MedicineDetailScreen({super.key, required this.medicine});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: Text('Are you sure you want to delete ${medicine.name}? All scheduled reminders and history for this medicine will be permanently removed.'),
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
      final medProvider = Provider.of<MedicineProvider>(context, listen: false);
      await medProvider.deleteMedicine(medicine);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${medicine.name} was removed'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final medProvider = Provider.of<MedicineProvider>(context);

    // Get up-to-date model
    final currentMed = medProvider.allMedicines.firstWhere(
      (m) => m.id == medicine.id,
      orElse: () => medicine,
    );

    final stockRatio = currentMed.totalStock > 0 ? (currentMed.remainingStock / currentMed.totalStock) : 0.0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(currentMed.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddEditMedicineScreen(medicine: currentMed)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Overview Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.medication_rounded, size: 36, color: AppColors.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentMed.name,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${currentMed.medicineType} • ${currentMed.dosage}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: currentMed.isActive
                                      ? AppColors.success.withValues(alpha: 0.12)
                                      : Colors.grey.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  currentMed.isActive ? 'Active Treatment' : 'Treatment Finished',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: currentMed.isActive ? AppColors.success : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    // Quick Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => medProvider.markDoseSkipped(medicine: currentMed),
                            icon: const Icon(Icons.skip_next_rounded, size: 18),
                            label: const Text('Skip'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.warning,
                              side: const BorderSide(color: AppColors.warning),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final smsResult = await medProvider.markDoseTaken(medicine: currentMed);
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
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Take Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Stock Tracker Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Remaining Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          '${currentMed.remainingStock} / ${currentMed.totalStock} Doses',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: currentMed.isLowStock ? AppColors.danger : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: stockRatio.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          currentMed.isLowStock ? AppColors.danger : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currentMed.isLowStock ? 'Stock running low! Refill recommended.' : 'Stock is sufficient',
                          style: TextStyle(
                            fontSize: 12,
                            color: currentMed.isLowStock ? AppColors.danger : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                        Text(
                          'Low alert: ≤ ${currentMed.lowStockThreshold}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Prescription Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Prescription Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    _buildDetailRow('Frequency', currentMed.frequency, Icons.repeat_rounded),
                    _buildDetailRow('Food Timing', currentMed.foodTiming, Icons.restaurant_rounded),
                    _buildDetailRow('Start Date', currentMed.startDate, Icons.calendar_today_rounded),
                    _buildDetailRow('End Date', currentMed.endDate, Icons.event_available_rounded),
                    if (currentMed.instructions.isNotEmpty)
                      _buildDetailRow('Instructions', currentMed.instructions, Icons.info_outline_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Daily Reminder Times
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Daily Reminders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    if (currentMed.schedules.isEmpty)
                      const Text('No daily schedules defined.')
                    else
                      Column(
                        children: currentMed.schedules.map((s) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.alarm, color: AppColors.primary),
                            title: Text(
                              AppDateUtils.formatTimeString(s.timeOfDay),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Dosage: ${s.dosageAmount}'),
                            trailing: StatusBadge(
                              label: s.isEnabled ? 'Enabled' : 'Disabled',
                              color: s.isEnabled ? AppColors.success : Colors.grey,
                            ),
                          );
                        }).toList(),
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

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.lightTextSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
