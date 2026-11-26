import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../database/database_helper.dart';
import '../utils/date_utils.dart';
import '../../models/appointment_model.dart';
import '../../models/medicine_history_model.dart';
import '../../models/medicine_model.dart';
import '../../models/medicine_schedule_model.dart';
import 'preference_service.dart';
import 'sms_service.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('[NotificationService] Background notification action received: ${notificationResponse.actionId}');
  NotificationService.handleNotificationAction(
    actionId: notificationResponse.actionId,
    payload: notificationResponse.payload,
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Application ID matching Gradle config
  static const String expectedApplicationId = 'com.caretrack.caretrack';

  // NEW high-priority notification channels (V5 ensures fresh Android channel registry)
  static const String channelId = 'caretrack_medicine_v5';
  static const String channelName = 'CareTrack Medicine Reminders';
  static const String channelDescription = 'Critical notifications for scheduled medication doses with sound and vibration';

  static const String appointmentChannelId = 'caretrack_appointment_v5';
  static const String appointmentChannelName = 'Doctor Appointment Reminders';
  static const String appointmentChannelDescription = 'Audible reminders for upcoming clinical appointments';

  static const String lowStockChannelId = 'caretrack_low_stock_v5';
  static const String lowStockChannelName = 'Low Stock Alerts';
  static const String lowStockChannelDescription = 'Alerts when medicine stock is running low';

  // Safe fallback vibration pattern (wait 0ms, vibrate 500ms, sleep 250ms, vibrate 500ms)
  static final Int64List _vibrationPattern = Int64List.fromList([0, 500, 250, 500, 250, 500]);

  /// Initialize Timezones with robust device location detection
  void _initTimeZones() {
    try {
      tz.initializeTimeZones();

      final now = DateTime.now();
      final tzName = now.timeZoneName;
      final offset = now.timeZoneOffset;
      tz.Location? detectedLoc;

      // 1. Direct name lookup
      try {
        detectedLoc = tz.getLocation(tzName);
      } catch (_) {}

      // 2. Common timezone name aliases (e.g. IST -> Asia/Kolkata)
      if (detectedLoc == null) {
        const aliases = {
          'IST': 'Asia/Kolkata',
          'India Standard Time': 'Asia/Kolkata',
          'EDT': 'America/New_York',
          'EST': 'America/New_York',
          'CDT': 'America/Chicago',
          'CST': 'America/Chicago',
          'MDT': 'America/Denver',
          'MST': 'America/Denver',
          'PDT': 'America/Los_Angeles',
          'PST': 'America/Los_Angeles',
          'GMT': 'Etc/GMT',
          'UTC': 'Etc/UTC',
          'BST': 'Europe/London',
          'CET': 'Europe/Paris',
          'CEST': 'Europe/Paris',
          'JST': 'Asia/Tokyo',
          'AEST': 'Australia/Sydney',
          'AEDT': 'Australia/Sydney',
          'SGT': 'Asia/Singapore',
          'HKT': 'Asia/Hong_Kong',
          'PKT': 'Asia/Karachi',
          'NPT': 'Asia/Kathmandu',
        };

        final aliasKey = aliases[tzName];
        if (aliasKey != null) {
          try {
            detectedLoc = tz.getLocation(aliasKey);
          } catch (_) {}
        }
      }

      // 3. Offset matching fallback
      if (detectedLoc == null) {
        for (final loc in tz.timeZoneDatabase.locations.values) {
          if (loc.currentTimeZone.offset == offset.inMilliseconds) {
            detectedLoc = loc;
            break;
          }
        }
      }

      // 4. Default to UTC if completely unresolvable
      detectedLoc ??= tz.getLocation('UTC');

      tz.setLocalLocation(detectedLoc);
      debugPrint('[NotificationService] Timezone initialized. Location: ${tz.local.name}, Current TZ time: ${tz.TZDateTime.now(tz.local)} (Device: $now)');
    } catch (e) {
      debugPrint('[NotificationService] Error initializing timezones: $e');
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[NotificationService] Already initialized.');
      return;
    }

    debugPrint('[NotificationService] Starting initialization for app: $expectedApplicationId');

    // 1. Initialize Timezones accurately
    _initTimeZones();

    // 2. Platform initialization settings using dedicated drawable 'app_icon'
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    final bool? initResult = await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('[NotificationService] Notification tapped foreground: actionId=${response.actionId}, payload=${response.payload}');
        handleNotificationAction(
          actionId: response.actionId,
          payload: response.payload,
        );
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    debugPrint('[NotificationService] Plugin.initialize() returned: $initResult');

    // 3. Create High-Importance Android Notification Channels
    await _createNotificationChannels();

    // 4. Cancel all legacy/test notification IDs completely
    const testIds = [77777, 88888, 99991, 99999];
    for (final id in testIds) {
      await cancelNotification(id);
    }

    // 5. Clean test database records if present
    try {
      await DatabaseHelper.instance.cleanTestRecords();
    } catch (_) {}

    _isInitialized = true;
    debugPrint('[NotificationService] Initialization complete.');

    // 6. Restore valid active medicine reminders into AlarmManager
    try {
      await restoreAllActiveMedicineReminders();
    } catch (e) {
      debugPrint('[NotificationService] Error restoring active reminders on startup: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation == null) {
      debugPrint('[NotificationService] Android implementation not found; skipping channel setup.');
      return;
    }

    try {
      // 1. Medicine Reminder Channel (MAX importance, Sound ON, Vibration ON)
      final medicineChannel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
        enableLights: true,
        showBadge: true,
      );
      await androidImplementation.createNotificationChannel(medicineChannel);
      debugPrint('[NotificationService] Channel created: $channelId (Importance: MAX, Sound: true, Vibration: true)');

      // 2. Appointment Channel (MAX importance, Sound ON, Vibration ON)
      final appointmentChannel = AndroidNotificationChannel(
        appointmentChannelId,
        appointmentChannelName,
        description: appointmentChannelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
        enableLights: true,
        showBadge: true,
      );
      await androidImplementation.createNotificationChannel(appointmentChannel);
      debugPrint('[NotificationService] Channel created: $appointmentChannelId');

      // 3. Low Stock Channel (HIGH importance)
      const lowStockChannel = AndroidNotificationChannel(
        lowStockChannelId,
        lowStockChannelName,
        description: lowStockChannelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      await androidImplementation.createNotificationChannel(lowStockChannel);
      debugPrint('[NotificationService] Channel created: $lowStockChannelId');
    } catch (e) {
      debugPrint('[NotificationService] Error creating notification channels: $e');
    }
  }

  /// Request permissions for POST_NOTIFICATIONS and exact alarms
  Future<bool> requestPermissions() async {
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      debugPrint('[NotificationService] Requesting Android notification and exact alarm permissions...');
      final grantedNotification = await androidImplementation.requestNotificationsPermission();
      final grantedExactAlarm = await androidImplementation.requestExactAlarmsPermission();
      final canExact = await androidImplementation.canScheduleExactNotifications();

      debugPrint('[NotificationService] Permissions result: notifications=$grantedNotification, exactAlarmRequest=$grantedExactAlarm, canScheduleExact=$canExact');
      return (grantedNotification ?? false);
    }
    return false;
  }

  /// Diagnostic check of permissions, channels, and pending notifications
  Future<Map<String, dynamic>> checkDiagnostics() async {
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    bool? canExact = false;
    bool areNotificationsEnabled = false;
    List<String> channelDetails = [];

    if (androidImplementation != null) {
      canExact = await androidImplementation.canScheduleExactNotifications();
      areNotificationsEnabled = await androidImplementation.areNotificationsEnabled() ?? false;
      final channels = await androidImplementation.getNotificationChannels();
      if (channels != null) {
        for (var c in channels) {
          channelDetails.add('${c.id} (importance: ${c.importance.name}, sound: ${c.playSound})');
        }
      }
    }

    final pending = await _notificationsPlugin.pendingNotificationRequests();

    final result = {
      'applicationId': expectedApplicationId,
      'isInitialized': _isInitialized,
      'timezoneLocation': tz.local.name,
      'timezoneNow': tz.TZDateTime.now(tz.local).toString(),
      'systemNow': DateTime.now().toString(),
      'areNotificationsEnabled': areNotificationsEnabled,
      'canScheduleExactNotifications': canExact,
      'channelsCount': channelDetails.length,
      'channels': channelDetails,
      'pendingNotificationsCount': pending.length,
    };

    debugPrint('[NotificationService] Diagnostics: $result');
    return result;
  }

  /// Calculate next valid DateTime for a medicine schedule
  /// Respects device timezone, medicine start date, end date, and never returns past timestamps.
  tz.TZDateTime? calculateNextScheduleDateTime({
    required MedicineModel medicine,
    required MedicineScheduleModel schedule,
  }) {
    final parts = schedule.timeOfDay.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    final tzNow = tz.TZDateTime.now(tz.local);
    final nowLocal = DateTime.now();

    // 1. Verify if medicine course has already expired
    DateTime? start = DateTime.tryParse(medicine.startDate);
    DateTime? end = DateTime.tryParse(medicine.endDate);

    if (end != null) {
      final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
      if (nowLocal.isAfter(endOfDay)) {
        debugPrint('[NotificationService] Course for ${medicine.name} ended on ${medicine.endDate}. Not scheduling.');
        return null;
      }
    }

    // 2. Calculate candidate scheduled DateTime in device timezone
    tz.TZDateTime target;
    if (start != null) {
      final startDay = DateTime(start.year, start.month, start.day);
      final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);

      if (startDay.isAfter(today)) {
        // Start date is in the future: first reminder triggers on start date at scheduled time
        target = tz.TZDateTime(tz.local, start.year, start.month, start.day, hour, minute);
      } else {
        // Start date is today or in past: candidate is today at scheduled time
        target = tz.TZDateTime(tz.local, tzNow.year, tzNow.month, tzNow.day, hour, minute);
        if (target.isBefore(tzNow)) {
          // If today's time has already passed, schedule for tomorrow
          target = target.add(const Duration(days: 1));
        }
      }
    } else {
      target = tz.TZDateTime(tz.local, tzNow.year, tzNow.month, tzNow.day, hour, minute);
      if (target.isBefore(tzNow)) {
        target = target.add(const Duration(days: 1));
      }
    }

    // 3. Verify candidate does not exceed course end date
    if (end != null) {
      final endOfDay = tz.TZDateTime(tz.local, end.year, end.month, end.day, 23, 59, 59);
      if (target.isAfter(endOfDay)) {
        debugPrint('[NotificationService] Next reminder for ${medicine.name} ($target) exceeds course end date ($endOfDay). Not scheduling.');
        return null;
      }
    }

    return target;
  }

  /// Schedule a medicine reminder using actual saved medicine details
  /// Notification format:
  /// Title: CareTrack – Medicine Reminder
  /// Message: It is time to take [Medicine Name] ([Dosage]).
  Future<void> scheduleMedicineReminder({
    required MedicineModel medicine,
    required MedicineScheduleModel schedule,
  }) async {
    if (!medicine.isActive || !schedule.isEnabled) {
      debugPrint('[NotificationService] Skipping reminder for ${medicine.name}: active=${medicine.isActive}, enabled=${schedule.isEnabled}');
      return;
    }

    if (!_isInitialized) {
      await initialize();
    }

    final scheduledDate = calculateNextScheduleDateTime(
      medicine: medicine,
      schedule: schedule,
    );

    if (scheduledDate == null) {
      debugPrint('[NotificationService] No valid upcoming schedule for ${medicine.name} (${schedule.timeOfDay}, range: ${medicine.startDate} to ${medicine.endDate})');
      return;
    }

    final dosageText = schedule.dosageAmount.isNotEmpty ? schedule.dosageAmount : medicine.dosage;
    final dosageFormatted = dosageText.isNotEmpty ? ' ($dosageText)' : '';
    const String title = 'CareTrack – Medicine Reminder';
    final String messageBody = 'It is time to take ${medicine.name}$dosageFormatted.';
    final String timeFormatted = AppDateUtils.formatTimeString(schedule.timeOfDay);

    final payload = jsonEncode({
      'medicineId': medicine.id,
      'userId': medicine.userId,
      'scheduleId': schedule.id,
      'medicineName': medicine.name,
      'dosage': dosageText,
      'notificationId': schedule.notificationId,
      'timeOfDay': schedule.timeOfDay,
    });

    final prefs = await PreferenceService.getInstance();
    final playSound = prefs.isSoundEnabled();
    final enableVibration = prefs.isVibrationEnabled();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: playSound,
      enableVibration: enableVibration,
      vibrationPattern: enableVibration ? _vibrationPattern : null,
      icon: 'app_icon',
      category: AndroidNotificationCategory.reminder,
      styleInformation: BigTextStyleInformation(
        messageBody,
        contentTitle: title,
        summaryText: 'Medicine Due: $timeFormatted',
      ),
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_taken',
          'Mark as Taken',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'action_skipped',
          'Skip',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'action_snooze',
          'Snooze',
          showsUserInterface: false,
        ),
      ],
    );

    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final canExact = await androidImplementation?.canScheduleExactNotifications() ?? false;
    final mode = canExact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;
    final matchComponents = (medicine.frequency == 'As needed') ? null : DateTimeComponents.time;

    try {
      await _notificationsPlugin.zonedSchedule(
        schedule.notificationId,
        title,
        messageBody,
        scheduledDate,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchComponents,
        payload: payload,
      );
      debugPrint('[NotificationService] Scheduled reminder for ${medicine.name} at $scheduledDate (ID: ${schedule.notificationId}, Channel: $channelId, Mode: $mode, Repeat: $matchComponents)');
    } catch (e) {
      debugPrint('[NotificationService] Exact scheduling failed for ${medicine.name}, falling back to inexact mode: $e');
      try {
        await _notificationsPlugin.zonedSchedule(
          schedule.notificationId,
          title,
          messageBody,
          scheduledDate,
          NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: matchComponents,
          payload: payload,
        );
        debugPrint('[NotificationService] Scheduled via inexact fallback for ${medicine.name}');
      } catch (e2) {
        debugPrint('[NotificationService] ERROR scheduling medicine notification: $e2');
      }
    }
  }

  /// Restore all active user medicine reminders from SQLite database into AlarmManager
  Future<int> restoreAllActiveMedicineReminders() async {
    int scheduledCount = 0;
    try {
      debugPrint('[NotificationService] Restoring all active medicine reminders from database...');
      final db = DatabaseHelper.instance;
      final medicines = await db.getMedicines(activeOnly: true);
      final now = DateTime.now();

      for (var med in medicines) {
        if (!med.isActive) continue;

        // Check if course has ended
        if (med.endDate.isNotEmpty) {
          final end = DateTime.tryParse(med.endDate);
          if (end != null) {
            final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
            if (now.isAfter(endOfDay)) {
              await cancelMedicineReminders(med);
              continue;
            }
          }
        }

        for (var schedule in med.schedules) {
          if (schedule.isEnabled) {
            await scheduleMedicineReminder(medicine: med, schedule: schedule);
            scheduledCount++;
          }
        }
      }
      debugPrint('[NotificationService] Completed restoration of $scheduledCount active medicine schedules.');
    } catch (e) {
      debugPrint('[NotificationService] Error restoring active medicine reminders: $e');
    }
    return scheduledCount;
  }

  /// Schedule appointment reminder
  Future<void> scheduleAppointmentReminder({
    required AppointmentModel appointment,
    int minutesBefore = 60,
  }) async {
    if (appointment.isCompleted) return;
    if (!_isInitialized) await initialize();

    final apptTime = appointment.appointmentDateTime;
    var reminderTime = apptTime.subtract(Duration(minutes: minutesBefore));
    if (reminderTime.isBefore(DateTime.now())) {
      if (apptTime.isAfter(DateTime.now())) {
        reminderTime = DateTime.now().add(const Duration(minutes: 1));
      } else {
        return;
      }
    }

    final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

    final payload = jsonEncode({
      'appointmentId': appointment.id,
      'doctorName': appointment.doctorName,
      'hospitalName': appointment.hospitalName,
      'isAppointment': true,
    });

    final String title = 'CareTrack – Doctor Appointment';
    final String timeFormatted = AppDateUtils.formatTimeString(appointment.appointmentTime);
    final String body = 'Upcoming appointment with Dr. ${appointment.doctorName} (${appointment.specialization})\n'
        'Hospital: ${appointment.hospitalName}\n'
        'Time: $timeFormatted on ${appointment.appointmentDate}';

    final androidDetails = AndroidNotificationDetails(
      appointmentChannelId,
      appointmentChannelName,
      channelDescription: appointmentChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: _vibrationPattern,
      icon: 'app_icon',
      category: AndroidNotificationCategory.event,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Appointment Alert',
      ),
    );

    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final canExact = await androidImplementation?.canScheduleExactNotifications() ?? false;
    final mode = canExact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;

    try {
      await _notificationsPlugin.zonedSchedule(
        appointment.notificationId,
        title,
        body,
        scheduledDate,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      debugPrint('[NotificationService] Scheduled appointment reminder for Dr. ${appointment.doctorName} at $scheduledDate (ID: ${appointment.notificationId})');
    } catch (e) {
      debugPrint('[NotificationService] Error scheduling appointment reminder: $e');
    }
  }

  /// Cancel a specific scheduled notification
  Future<void> cancelNotification(int notificationId) async {
    try {
      await _notificationsPlugin.cancel(notificationId);
      debugPrint('[NotificationService] Cancelled notification ID: $notificationId');
    } catch (e) {
      debugPrint('[NotificationService] Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications for a medicine
  Future<void> cancelMedicineReminders(MedicineModel medicine) async {
    debugPrint('[NotificationService] Cancelling reminders for medicine: ${medicine.name} (ID: ${medicine.id})');
    for (var schedule in medicine.schedules) {
      await cancelNotification(schedule.notificationId);
    }
    // Defensively cancel deterministic slots 1..20 for this medicine ID
    if (medicine.id != null) {
      for (int i = 1; i <= 20; i++) {
        await cancelNotification((medicine.id! * 100) + i);
      }
    }
  }

  /// Reschedule all reminders for a medicine
  Future<void> rescheduleMedicineReminders(MedicineModel medicine) async {
    debugPrint('[NotificationService] Rescheduling reminders for medicine: ${medicine.name}');
    await cancelMedicineReminders(medicine);
    if (!medicine.isActive) {
      debugPrint('[NotificationService] Medicine ${medicine.name} is inactive; skipping reschedule.');
      return;
    }
    for (var schedule in medicine.schedules) {
      if (schedule.isEnabled) {
        await scheduleMedicineReminder(medicine: medicine, schedule: schedule);
      }
    }
  }

  /// Snooze reminder for specified minutes (default 10, or 5/15)
  Future<void> snoozeReminder({
    required int medicineId,
    required String medicineName,
    required String dosage,
    int? minutes,
  }) async {
    if (!_isInitialized) await initialize();

    final prefs = await PreferenceService.getInstance();
    final snoozeMinutes = minutes ?? prefs.getSnoozeMinutes();
    final snoozeTime = tz.TZDateTime.now(tz.local).add(Duration(minutes: snoozeMinutes));

    final snoozeNotificationId = (medicineId * 1000) + DateTime.now().minute;

    final payload = jsonEncode({
      'medicineId': medicineId,
      'medicineName': medicineName,
      'dosage': dosage,
      'notificationId': snoozeNotificationId,
      'isSnooze': true,
    });

    const String title = 'CareTrack – Medicine Reminder (Snoozed)';
    final dosageFormatted = dosage.isNotEmpty ? ' ($dosage)' : '';
    final String messageBody = 'It is time to take $medicineName$dosageFormatted.\n'
        'Reminder after $snoozeMinutes minutes.';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: _vibrationPattern,
      icon: 'app_icon',
      category: AndroidNotificationCategory.reminder,
      styleInformation: BigTextStyleInformation(
        messageBody,
        contentTitle: title,
      ),
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_taken',
          'Mark as Taken',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'action_skipped',
          'Skip',
          showsUserInterface: false,
        ),
      ],
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        snoozeNotificationId,
        title,
        messageBody,
        snoozeTime,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      debugPrint('[NotificationService] Scheduled snooze reminder for $medicineName in $snoozeMinutes mins (ID: $snoozeNotificationId)');
    } catch (e) {
      debugPrint('[NotificationService] Error scheduling snooze: $e');
    }
  }

  /// Show immediate Low-Stock Notification
  Future<void> showLowStockNotification({
    required int medicineId,
    required String medicineName,
    required int remainingStock,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      lowStockChannelId,
      lowStockChannelName,
      channelDescription: lowStockChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: 'app_icon',
    );

    try {
      await _notificationsPlugin.show(
        medicineId + 50000,
        'Low Stock Alert: $medicineName',
        'Only $remainingStock doses remaining. Please refill soon.',
        const NotificationDetails(android: androidDetails),
      );
      debugPrint('[NotificationService] Low stock notification shown for $medicineName');
    } catch (e) {
      debugPrint('[NotificationService] Error showing low stock notification: $e');
    }
  }

  /// Retrieve list of pending notification requests
  Future<List<PendingNotificationRequest>> getPendingNotificationRequests() async {
    final list = await _notificationsPlugin.pendingNotificationRequests();
    debugPrint('[NotificationService] Pending notifications count: ${list.length}');
    for (var r in list) {
      debugPrint('[NotificationService]   -> Pending ID: ${r.id}, Title: ${r.title}, Body: ${r.body}');
    }
    return list;
  }

  /// Handle action buttons: Taken, Skipped, Snooze
  static Future<void> handleNotificationAction({
    String? actionId,
    String? payload,
  }) async {
    debugPrint('[NotificationService] Handling action: $actionId, payload: $payload');
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final medicineId = data['medicineId'] as int;
      final userId = data['userId'] as int? ?? 1;
      final scheduleId = data['scheduleId'] as int?;
      final medicineName = data['medicineName'] as String? ?? 'Medicine';
      final dosage = data['dosage'] as String? ?? '';
      final now = DateTime.now();

      final db = DatabaseHelper.instance;

      if (actionId == 'action_taken') {
        debugPrint('[NotificationService] Action: Mark as Taken');
        // 1. Record as Taken in database
        await db.insertMedicineHistory(
          MedicineHistoryModel(
            medicineId: medicineId,
            scheduleId: scheduleId,
            medicineName: medicineName,
            dosage: dosage,
            scheduledTime: now.toIso8601String(),
            actualTime: now.toIso8601String(),
            status: 'taken',
            notes: 'Marked as taken via notification',
            createdAt: now.toIso8601String(),
          ),
        );

        // 2. Decrement remaining stock
        final med = await db.getMedicineById(medicineId);
        if (med != null && med.remainingStock > 0) {
          final updatedStock = med.remainingStock - 1;
          await db.updateMedicineStock(medicineId, updatedStock);

          // Check low stock threshold
          if (updatedStock <= med.lowStockThreshold) {
            NotificationService().showLowStockNotification(
              medicineId: medicineId,
              medicineName: med.name,
              remainingStock: updatedStock,
            );
          }
        }

        // 3. Check if medicine course has ended; cancel future reminders if completed
        if (med != null && med.endDate.isNotEmpty) {
          final end = DateTime.tryParse(med.endDate);
          if (end != null) {
            final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
            if (now.isAfter(endOfDay)) {
              await NotificationService().cancelMedicineReminders(med);
            }
          }
        }

        // 4. Trigger Emergency Contact SMS alert only AFTER Taken status is saved in database
        await SmsService().sendTakenAlertToEmergencyContact(
          userId: userId,
          medicineId: medicineId,
          medicineName: medicineName,
          dosage: dosage,
          takenTime: now,
        );
      } else if (actionId == 'action_skipped') {
        debugPrint('[NotificationService] Action: Skip');
        await db.insertMedicineHistory(
          MedicineHistoryModel(
            medicineId: medicineId,
            scheduleId: scheduleId,
            medicineName: medicineName,
            dosage: dosage,
            scheduledTime: now.toIso8601String(),
            actualTime: now.toIso8601String(),
            status: 'skipped',
            notes: 'Skipped via notification',
            createdAt: now.toIso8601String(),
          ),
        );
      } else if (actionId == 'action_snooze') {
        debugPrint('[NotificationService] Action: Snooze');
        await NotificationService().snoozeReminder(
          medicineId: medicineId,
          medicineName: medicineName,
          dosage: dosage,
        );
      }
    } catch (e, stack) {
      debugPrint('[NotificationService] Error handling notification action: $e\n$stack');
    }
  }
}
