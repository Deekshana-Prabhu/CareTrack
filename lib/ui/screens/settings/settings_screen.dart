import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/health_reference.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/notification_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/medicine_provider.dart';
import '../../../providers/health_provider.dart';
import '../auth/login_screen.dart';
import '../profile/edit_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _exportData(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return;

    try {
      final jsonStr = await settings.exportData(user.id!);
      await Share.share(jsonStr, subject: 'CareTrack_Backup_${user.name}.json');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final med = Provider.of<MedicineProvider>(context, listen: false);
    final health = Provider.of<HealthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return;

    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Backup JSON'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste your exported CareTrack JSON backup text below:'),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '{"app": "CareTrack", ...}',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Import')),
        ],
      ),
    );

    if (result == true && controller.text.isNotEmpty && context.mounted) {
      final success = await settings.importData(controller.text, user.id!);
      if (context.mounted) {
        if (success) {
          await med.loadMedicines(user.id!);
          await health.loadHealthData(user.id!);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup data imported successfully!'), backgroundColor: AppColors.success),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid backup format or import error.'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  void _showSmsLogsDialog(BuildContext context, int userId) async {
    final logs = await DatabaseHelper.instance.getSmsLogs(userId: userId);
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emergency SMS History'),
        content: SizedBox(
          width: double.maxFinite,
          child: logs.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No emergency SMS alerts logged yet. Alerts trigger when doses are marked as Taken.'),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: logs.length,
                  separatorBuilder: (_, _) => const Divider(height: 12),
                  itemBuilder: (context, idx) {
                    final item = logs[idx];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.medicineName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('To: ${item.recipientPhone} (${item.status})', style: const TextStyle(fontSize: 12)),
                          Text(item.sentAt.substring(0, 16), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      trailing: Icon(
                        item.status == 'FAILED' ? Icons.error_outline : Icons.check_circle_outline,
                        color: item.status == 'FAILED' ? AppColors.danger : AppColors.success,
                        size: 20,
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _syncActiveReminders(BuildContext context) async {
    final count = await NotificationService().restoreAllActiveMedicineReminders();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully synchronized $count active medicine reminder(s) with Android system.'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showDiagnosticsDialog(BuildContext context) async {
    final diag = await NotificationService().checkDiagnostics();
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Diagnostics & Status', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Application ID: ${diag['applicationId']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              Text('Notifications Enabled: ${diag['areNotificationsEnabled'] ? "YES (Active)" : "NO (Blocked in Android Settings)"}'),
              Text('Exact Alarms Allowed: ${diag['canScheduleExactNotifications'] ? "YES" : "NO (Will use inexact fallback)"}'),
              Text('Timezone Location: ${diag['timezoneLocation']}'),
              Text('Timezone Time: ${diag['timezoneNow'].toString().substring(0, 19)}'),
              Text('Device System Time: ${diag['systemNow'].toString().substring(0, 19)}'),
              const Divider(),
              Text('Notification Channels (${diag['channelsCount']}):', style: const TextStyle(fontWeight: FontWeight.bold)),
              if ((diag['channels'] as List).isEmpty)
                const Text('  No channels registered yet')
              else
                ...(diag['channels'] as List).map((ch) => Text('  • $ch', style: const TextStyle(fontSize: 12))),
              const Divider(),
              Text('Pending Scheduled Alerts: ${diag['pendingNotificationsCount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppStrings.appName,
      applicationVersion: AppStrings.appVersion,
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.healing_rounded, color: Colors.white, size: 28),
      ),
      children: const [
        Text(
          'CareTrack is a comprehensive Mobile-Based Medicine Reminder and Patient Health Monitoring System designed to help patients manage daily prescriptions, prevent missed doses, and track essential health vitals.',
        ),
        SizedBox(height: 12),
        Text(
          'Designed & Developed with Flutter, SQLite, Local Notifications, fl_chart, and PDF reporting.',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy & Medical Disclaimer'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Data Privacy', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text(
                'All user profile credentials, prescriptions, and health vitals records are stored 100% locally on your device within an encrypted/isolated SQLite database. CareTrack does not transmit your personal medical data to any external server.',
              ),
              const SizedBox(height: 14),
              const Text('Medical Advice Disclaimer', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                HealthReference.disclaimer,
                style: const TextStyle(height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Understood')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = Provider.of<SettingsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Section: Appearance
          _buildSectionHeader('Appearance'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Switch between light and dark visual themes'),
                  value: settings.isDarkMode,
                  onChanged: (val) => settings.toggleDarkMode(val),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Medicine Notifications & Reminders
          _buildSectionHeader('Reminders & Alerts'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                  title: const Text('Medicine Notifications'),
                  subtitle: const Text('Receive timely scheduled medication alerts'),
                  value: settings.notificationsEnabled,
                  onChanged: (val) => settings.toggleNotifications(val),
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.event_note_rounded, color: AppColors.secondary),
                  title: const Text('Appointment Reminders'),
                  subtitle: const Text('Receive alerts before scheduled doctor visits'),
                  value: settings.appointmentNotificationsEnabled,
                  onChanged: (val) => settings.toggleAppointmentNotifications(val),
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up_outlined, color: AppColors.primary),
                  title: const Text('Notification Sound'),
                  subtitle: const Text('Audible alert using device reminder sound'),
                  value: settings.soundEnabled,
                  onChanged: (val) => settings.toggleSound(val),
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration_rounded, color: AppColors.primary),
                  title: const Text('Vibration'),
                  subtitle: const Text('Vibrate phone when medicine or appointment is due'),
                  value: settings.vibrationEnabled,
                  onChanged: (val) => settings.toggleVibration(val),
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.snooze_rounded, color: AppColors.primary),
                  title: const Text('Default Snooze Duration'),
                  subtitle: Text('${settings.snoozeMinutes} minutes'),
                  trailing: DropdownButton<int>(
                    value: settings.snoozeMinutes,
                    underline: const SizedBox.shrink(),
                    items: const [5, 10, 15]
                        .map((m) => DropdownMenuItem(value: m, child: Text('$m mins')))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) settings.setSnoozeMinutes(val);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.sync_rounded, color: AppColors.primary),
                  title: const Text('Sync Medicine Reminders', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Restore active medicine reminders in Android system alarms'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('SYNC NOW', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  onTap: () => _syncActiveReminders(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.analytics_outlined, color: AppColors.secondary),
                  title: const Text('Notification Diagnostics'),
                  subtitle: const Text('Inspect channels, permissions, & pending alarms'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showDiagnosticsDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security_update_good_rounded, color: AppColors.secondary),
                  title: const Text('Check Android Permissions'),
                  subtitle: const Text('Verify exact-alarm and notification permissions'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final granted = await NotificationService().requestPermissions();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(granted ? 'All notification permissions granted!' : 'Permissions updated'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                ),
                if (user != null) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.sms_outlined, color: AppColors.primary),
                    title: const Text('Emergency SMS Alerts History'),
                    subtitle: const Text('View sent emergency notifications for taken doses'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showSmsLogsDialog(context, user.id!),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Data & Backup
          _buildSectionHeader('Data Management'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined, color: AppColors.primary),
                  title: const Text('Export Health Data Backup'),
                  subtitle: const Text('Export all medicines and vitals to JSON'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _exportData(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined, color: AppColors.primary),
                  title: const Text('Import Health Data Backup'),
                  subtitle: const Text('Restore records from exported JSON'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _importData(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: About & Privacy
          _buildSectionHeader('About & Privacy'),
          Card(
            child: Column(
              children: [
                if (user != null) ...[
                  ListTile(
                    leading: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                    title: const Text('Edit Patient Profile'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
                      );
                    },
                  ),
                  const Divider(height: 1),
                ],
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                  title: const Text('Privacy Policy & Medical Disclaimer'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showPrivacyDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                  title: const Text('About CareTrack'),
                  subtitle: const Text('Version 1.0.0'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sign Out Button
          ElevatedButton.icon(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
