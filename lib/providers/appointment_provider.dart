import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';
import '../core/services/notification_service.dart';
import '../models/appointment_model.dart';

enum AppointmentFilter { all, upcoming, completed }

class AppointmentProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService();

  List<AppointmentModel> _appointments = [];
  AppointmentModel? _nextAppointment;
  AppointmentFilter _filter = AppointmentFilter.upcoming;
  bool _isLoading = false;
  String? _errorMessage;

  List<AppointmentModel> get allAppointments => _appointments;
  AppointmentModel? get nextAppointment => _nextAppointment;
  AppointmentFilter get filter => _filter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<AppointmentModel> get filteredAppointments {
    switch (_filter) {
      case AppointmentFilter.upcoming:
        return _appointments.where((a) => a.isUpcoming).toList();
      case AppointmentFilter.completed:
        return _appointments.where((a) => a.isCompleted || !a.isUpcoming).toList();
      case AppointmentFilter.all:
        return _appointments;
    }
  }

  void setFilter(AppointmentFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  Future<void> loadAppointments(int userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _appointments = await _dbHelper.getAppointments(userId: userId);
      _nextAppointment = await _dbHelper.getNextUpcomingAppointment(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load appointments: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAppointment(AppointmentModel appointment, {int reminderMinutes = 60}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final id = await _dbHelper.insertAppointment(appointment);
      final created = appointment.copyWith(id: id);

      // Schedule reminder
      await _notificationService.scheduleAppointmentReminder(
        appointment: created,
        minutesBefore: reminderMinutes,
      );

      await loadAppointments(appointment.userId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add appointment: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAppointment(AppointmentModel appointment, {int reminderMinutes = 60}) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _dbHelper.updateAppointment(appointment);

      // Cancel old and reschedule
      await _notificationService.cancelNotification(appointment.notificationId);
      if (!appointment.isCompleted) {
        await _notificationService.scheduleAppointmentReminder(
          appointment: appointment,
          minutesBefore: reminderMinutes,
        );
      }

      await loadAppointments(appointment.userId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update appointment: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAppointment(AppointmentModel appointment) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _notificationService.cancelNotification(appointment.notificationId);
      if (appointment.id != null) {
        await _dbHelper.deleteAppointment(appointment.id!);
      }

      await loadAppointments(appointment.userId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete appointment: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> markCompleted(AppointmentModel appointment) async {
    final updated = appointment.copyWith(isCompleted: !appointment.isCompleted);
    await updateAppointment(updated);
  }
}
