import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const String _keyUserId = 'pref_current_user_id';
  static const String _keyDarkMode = 'pref_is_dark_mode';
  static const String _keyOnboarded = 'pref_is_onboarded';
  static const String _keyNotifications = 'pref_notifications_enabled';
  static const String _keyAppointmentNotifications = 'pref_appointment_notifications_enabled';
  static const String _keySound = 'pref_sound_enabled';
  static const String _keyVibration = 'pref_vibration_enabled';
  static const String _keySnoozeMinutes = 'pref_snooze_minutes';

  static PreferenceService? _instance;
  static SharedPreferences? _prefs;

  PreferenceService._();

  static Future<PreferenceService> getInstance() async {
    if (_instance == null) {
      _instance = PreferenceService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // Current logged in user ID
  int? getCurrentUserId() {
    return _prefs?.getInt(_keyUserId);
  }

  Future<bool> setCurrentUserId(int? userId) async {
    if (userId == null) {
      return await _prefs?.remove(_keyUserId) ?? false;
    }
    return await _prefs?.setInt(_keyUserId, userId) ?? false;
  }

  // Dark Mode
  bool isDarkMode() {
    return _prefs?.getBool(_keyDarkMode) ?? false;
  }

  Future<bool> setDarkMode(bool value) async {
    return await _prefs?.setBool(_keyDarkMode, value) ?? false;
  }

  // Onboarded
  bool isOnboarded() {
    return _prefs?.getBool(_keyOnboarded) ?? false;
  }

  Future<bool> setOnboarded(bool value) async {
    return await _prefs?.setBool(_keyOnboarded, value) ?? false;
  }

  // Notifications enabled
  bool areNotificationsEnabled() {
    return _prefs?.getBool(_keyNotifications) ?? true;
  }

  Future<bool> setNotificationsEnabled(bool value) async {
    return await _prefs?.setBool(_keyNotifications, value) ?? false;
  }

  // Appointment notifications enabled
  bool areAppointmentNotificationsEnabled() {
    return _prefs?.getBool(_keyAppointmentNotifications) ?? true;
  }

  Future<bool> setAppointmentNotificationsEnabled(bool value) async {
    return await _prefs?.setBool(_keyAppointmentNotifications, value) ?? false;
  }

  // Sound enabled
  bool isSoundEnabled() {
    return _prefs?.getBool(_keySound) ?? true;
  }

  Future<bool> setSoundEnabled(bool value) async {
    return await _prefs?.setBool(_keySound, value) ?? false;
  }

  // Vibration enabled
  bool isVibrationEnabled() {
    return _prefs?.getBool(_keyVibration) ?? true;
  }

  Future<bool> setVibrationEnabled(bool value) async {
    return await _prefs?.setBool(_keyVibration, value) ?? false;
  }

  // Snooze minutes
  int getSnoozeMinutes() {
    return _prefs?.getInt(_keySnoozeMinutes) ?? 10;
  }

  Future<bool> setSnoozeMinutes(int minutes) async {
    return await _prefs?.setInt(_keySnoozeMinutes, minutes) ?? false;
  }

  // Clear session on logout
  Future<void> clearSession() async {
    await _prefs?.remove(_keyUserId);
  }
}
