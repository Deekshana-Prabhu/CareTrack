import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/health_reference.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/medicine_model.dart';
import '../../../models/medicine_schedule_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/medicine_provider.dart';
import '../../../providers/health_provider.dart';
import '../../../providers/appointment_provider.dart';
import '../appointments/appointment_list_screen.dart';
import '../appointments/add_edit_appointment_screen.dart';
import '../medicine/add_edit_medicine_screen.dart';
import '../medicine/medicine_calendar_screen.dart';
import '../medicine/medicine_history_screen.dart';
import '../health/add_health_record_screen.dart';
import '../health/health_analytics_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final med = Provider.of<MedicineProvider>(context);
    final health = Provider.of<HealthProvider>(context);
    final appt = Provider.of<AppointmentProvider>(context);
    final user = auth.currentUser;

    final nextAppointment = appt.nextAppointment;

    final todaySchedule = med.getScheduleForDate(DateTime.now());
    final totalToday = todaySchedule.length;
    final takenToday = todaySchedule.where((s) => s['status'] == 'taken').length;
    final adherenceToday = totalToday > 0 ? ((takenToday / totalToday) * 100).toInt() : 100;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : 'C',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()},',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  user?.name ?? 'Patient',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note_rounded),
            tooltip: 'Appointments',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppointmentListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Medicine Calendar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MedicineCalendarScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (user?.id != null) {
            await med.loadMedicines(user!.id!);
            await health.loadHealthData(user.id!);
            await appt.loadAppointments(user.id!);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner / Adherence Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Today\'s Adherence',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$takenToday / $totalToday Doses',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          '$adherenceToday%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: totalToday > 0 ? (takenToday / totalToday) : 1.0,
                                  minHeight: 8,
                                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryLight),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                totalToday == 0
                                    ? 'No medicines scheduled for today'
                                    : takenToday == totalToday
                                        ? 'All doses completed today! Great job!'
                                        : '${totalToday - takenToday} dose(s) remaining today',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Low-Stock Alert Warning Card (if any)
              if (med.lowStockCount > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Low Medicine Stock Alert',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                            ),
                            Text(
                              '${med.lowStockCount} of your medicines are running low. Refill soon!',
                              style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Next Doctor Appointment Section
              const SizedBox(height: 16),
              Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppointmentListScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.event_available_rounded, color: AppColors.secondary, size: 20),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Next Appointment',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                            if (nextAppointment != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  nextAppointment.countdownText,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            else
                              const Text(
                                'View All',
                                style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (nextAppointment != null) ...[
                          Text(
                            'Dr. ${nextAppointment.doctorName} • ${nextAppointment.specialization}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                '${nextAppointment.appointmentDate} at ${AppDateUtils.formatTimeString(nextAppointment.appointmentTime)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.local_hospital_outlined, size: 14, color: AppColors.lightTextSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  nextAppointment.hospitalName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (nextAppointment.reason.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Reason: ${nextAppointment.reason}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ] else ...[
                          Row(
                            children: [
                              Text(
                                'No upcoming appointments scheduled',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AddEditAppointmentScreen()),
                                  );
                                },
                                child: const Text('+ Book Visit'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Quick Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddEditMedicineScreen()),
                        );
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text('+ Med', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddEditAppointmentScreen()),
                        );
                      },
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: const Text('+ Appt', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddHealthRecordScreen()),
                        );
                      },
                      icon: const Icon(Icons.add_chart_rounded, size: 16),
                      label: const Text('+ Vitals', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HealthAnalyticsScreen()),
                        );
                      },
                      icon: const Icon(Icons.insights_rounded, size: 16),
                      label: const Text('Trends', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Today's Scheduled Reminders
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Today\'s Schedule',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MedicineHistoryScreen()),
                      );
                    },
                    child: const Text('Full History'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (todaySchedule.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, size: 44, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          const SizedBox(height: 10),
                          const Text(
                            'No medicines scheduled for today',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add your prescription medicines to get automatic reminders',
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
                  itemCount: todaySchedule.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = todaySchedule[index];
                    final MedicineModel medicine = item['medicine'];
                    final MedicineScheduleModel schedule = item['schedule'];
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
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.medication_rounded, color: AppColors.primary, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        medicine.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${medicine.dosage} • ${medicine.foodTiming}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
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
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => med.snoozeDose(medicine: medicine, minutes: 10),
                                    icon: const Icon(Icons.snooze_rounded, size: 16),
                                    label: const Text('Snooze 10m'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () => med.markDoseSkipped(medicine: medicine, schedule: schedule),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      side: const BorderSide(color: AppColors.warning),
                                      foregroundColor: AppColors.warning,
                                    ),
                                    child: const Text('Skip'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final smsResult = await med.markDoseTaken(medicine: medicine, schedule: schedule);
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
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

              const SizedBox(height: 28),

              // Recent Health Vitals Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Health Vitals Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
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
              const SizedBox(height: 10),

              // Grid of Vitals
              Builder(
                builder: (context) {
                  final latest = health.latestRecords;
                  final bp = latest['blood_pressure'];
                  final glucose = latest['blood_glucose'];
                  final hr = latest['heart_rate'];
                  final weight = latest['weight'];

                  final bpEval = bp != null && bp.valueSecondary != null
                      ? HealthReference.evaluateBloodPressure(bp.valuePrimary, bp.valueSecondary!)
                      : null;
                  final glucoseEval = glucose != null
                      ? HealthReference.evaluateBloodGlucose(glucose.valuePrimary, context: glucose.mealContext ?? 'Fasting')
                      : null;
                  final hrEval = hr != null
                      ? HealthReference.evaluateHeartRate(hr.valuePrimary)
                      : null;

                  return GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.35,
                    children: [
                      StatCard(
                        title: 'Blood Pressure',
                        value: bp != null ? '${bp.valuePrimary.toInt()}/${bp.valueSecondary?.toInt()} mmHg' : '--/--',
                        subtitle: bpEval?.status ?? 'No records yet',
                        icon: Icons.favorite_rounded,
                        iconColor: bpEval?.color ?? AppColors.primary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddHealthRecordScreen(initialType: 'blood_pressure')),
                          );
                        },
                      ),
                      StatCard(
                        title: 'Blood Glucose',
                        value: glucose != null ? '${glucose.valuePrimary.toInt()} mg/dL' : '-- mg/dL',
                        subtitle: glucoseEval?.status ?? 'No records yet',
                        icon: Icons.bloodtype_rounded,
                        iconColor: glucoseEval?.color ?? AppColors.secondary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddHealthRecordScreen(initialType: 'blood_glucose')),
                          );
                        },
                      ),
                      StatCard(
                        title: 'Heart Rate',
                        value: hr != null ? '${hr.valuePrimary.toInt()} bpm' : '-- bpm',
                        subtitle: hrEval?.status ?? 'No records yet',
                        icon: Icons.monitor_heart_rounded,
                        iconColor: hrEval?.color ?? Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddHealthRecordScreen(initialType: 'heart_rate')),
                          );
                        },
                      ),
                      StatCard(
                        title: 'Body Weight',
                        value: weight != null ? '${weight.valuePrimary.toStringAsFixed(1)} kg' : '-- kg',
                        subtitle: weight != null ? 'Logged recently' : 'No records yet',
                        icon: Icons.scale_rounded,
                        iconColor: Colors.teal,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddHealthRecordScreen(initialType: 'weight')),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
