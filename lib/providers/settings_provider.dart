import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../core/services/preference_service.dart';
import '../models/medicine_model.dart';
import '../models/health_record_model.dart';

class SettingsProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  PreferenceService? _prefService;

  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _appointmentNotificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _snoozeMinutes = 10;
  bool _isLoading = false;

  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get appointmentNotificationsEnabled => _appointmentNotificationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  int get snoozeMinutes => _snoozeMinutes;
  bool get isLoading => _isLoading;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> initialize() async {
    _prefService = await PreferenceService.getInstance();
    _isDarkMode = _prefService?.isDarkMode() ?? false;
    _notificationsEnabled = _prefService?.areNotificationsEnabled() ?? true;
    _appointmentNotificationsEnabled = _prefService?.areAppointmentNotificationsEnabled() ?? true;
    _soundEnabled = _prefService?.isSoundEnabled() ?? true;
    _vibrationEnabled = _prefService?.isVibrationEnabled() ?? true;
    _snoozeMinutes = _prefService?.getSnoozeMinutes() ?? 10;
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    await _prefService?.setDarkMode(value);
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    await _prefService?.setNotificationsEnabled(value);
    notifyListeners();
  }

  Future<void> toggleAppointmentNotifications(bool value) async {
    _appointmentNotificationsEnabled = value;
    await _prefService?.setAppointmentNotificationsEnabled(value);
    notifyListeners();
  }

  Future<void> toggleSound(bool value) async {
    _soundEnabled = value;
    await _prefService?.setSoundEnabled(value);
    notifyListeners();
  }

  Future<void> toggleVibration(bool value) async {
    _vibrationEnabled = value;
    await _prefService?.setVibrationEnabled(value);
    notifyListeners();
  }

  Future<void> setSnoozeMinutes(int minutes) async {
    _snoozeMinutes = minutes;
    await _prefService?.setSnoozeMinutes(minutes);
    notifyListeners();
  }

  // Export full user database data as JSON string
  Future<String> exportData(int userId) async {
    final user = await _dbHelper.getUserById(userId);
    final medicines = await _dbHelper.getMedicines(userId: userId);
    final history = await _dbHelper.getMedicineHistory();
    final healthRecords = await _dbHelper.getHealthRecords(userId: userId);

    final exportMap = {
      'app': 'CareTrack',
      'exported_at': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'user': user?.toMap(),
      'medicines': medicines.map((m) => m.toMap()).toList(),
      'history': history.map((h) => h.toMap()).toList(),
      'health_records': healthRecords.map((hr) => hr.toMap()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportMap);
  }

  // Import JSON backup data
  Future<bool> importData(String jsonString, int currentUserId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Import medicines
      if (decoded.containsKey('medicines')) {
        final list = decoded['medicines'] as List<dynamic>;
        for (var item in list) {
          final medMap = item as Map<String, dynamic>;
          medMap['user_id'] = currentUserId;
          medMap.remove('id');
          await _dbHelper.insertMedicine(MedicineModel.fromMap(medMap));
        }
      }

      // Import health records
      if (decoded.containsKey('health_records')) {
        final list = decoded['health_records'] as List<dynamic>;
        for (var item in list) {
          final hrMap = item as Map<String, dynamic>;
          hrMap['user_id'] = currentUserId;
          hrMap.remove('id');
          await _dbHelper.insertHealthRecord(HealthRecordModel.fromMap(hrMap));
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error importing data: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
