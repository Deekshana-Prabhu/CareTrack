import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/appointment_model.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/auth_provider.dart';
import 'add_edit_appointment_screen.dart';

class AppointmentListScreen extends StatelessWidget {
  const AppointmentListScreen({super.key});

  Future<void> _deleteAppointment(BuildContext context, AppointmentModel appt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: Text('Cancel and remove appointment with Dr. ${appt.doctorName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = Provider.of<AppointmentProvider>(context, listen: false);
      await provider.deleteAppointment(appt);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment removed'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<AppointmentProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final appointments = provider.filteredAppointments;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Doctor Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Book Appointment',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditAppointmentScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: Center(
              child: SegmentedButton<AppointmentFilter>(
                segments: const [
                  ButtonSegment(value: AppointmentFilter.upcoming, label: Text('Upcoming')),
                  ButtonSegment(value: AppointmentFilter.completed, label: Text('Past / Completed')),
                  ButtonSegment(value: AppointmentFilter.all, label: Text('All')),
                ],
                selected: {provider.filter},
                onSelectionChanged: (set) => provider.setFilter(set.first),
              ),
            ),
          ),

          // Appointments List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (user?.id != null) {
                  await provider.loadAppointments(user!.id!);
                }
              },
              child: appointments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy_rounded,
                            size: 64,
                            color: isDark ? AppColors.darkTextSecondary : const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.filter == AppointmentFilter.upcoming
                                ? 'No upcoming doctor appointments'
                                : 'No appointments found',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Schedule visits with your doctor and get timely reminders',
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
                      itemCount: appointments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final appt = appointments[index];
                        return _buildAppointmentCard(context, appt, provider, isDark);
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditAppointmentScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Book Appointment'),
      ),
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    AppointmentModel appt,
    AppointmentProvider provider,
    bool isDark,
  ) {
    final formattedTime = AppDateUtils.formatTimeString(appt.appointmentTime);
    final isUpcoming = appt.isUpcoming;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isUpcoming ? AppColors.primary : Colors.grey).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.local_hospital_rounded,
                    color: isUpcoming ? AppColors.primary : Colors.grey,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Dr. ${appt.doctorName}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isUpcoming
                                  ? AppColors.secondary.withValues(alpha: 0.15)
                                  : Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isUpcoming ? AppColors.secondary : Colors.grey,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              appt.countdownText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isUpcoming ? AppColors.secondaryDark : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appt.specialization,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.lightTextSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              appt.hospitalName,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Date, Time, Reason
            Row(
              children: [
                const Icon(Icons.event_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  '${appt.appointmentDate} at $formattedTime',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            if (appt.reason.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Reason: ${appt.reason}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
            if (appt.notes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Notes: ${appt.notes}',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => provider.markCompleted(appt),
                  icon: Icon(
                    appt.isCompleted ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                    size: 16,
                  ),
                  label: Text(appt.isCompleted ? 'Mark Pending' : 'Mark Done'),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddEditAppointmentScreen(appointment: appt)),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                  tooltip: 'Delete',
                  onPressed: () => _deleteAppointment(context, appt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
