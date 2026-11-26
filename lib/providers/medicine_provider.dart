import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';
import '../core/services/notification_service.dart';
import '../core/services/sms_service.dart';
import '../models/medicine_model.dart';
import '../models/medicine_schedule_model.dart';
import '../models/medicine_history_model.dart';

enum MedicineFilter { all, active, completed, lowStock }

class MedicineProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService();

  List<MedicineModel> _medicines = [];
  List<MedicineHistoryModel> _history = [];
  MedicineFilter _currentFilter = MedicineFilter.all;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<MedicineModel> get medicines => _filteredMedicines();
  List<MedicineModel> get allMedicines => _medicines;
  List<MedicineHistoryModel> get history => _history;
  MedicineFilter get currentFilter => _currentFilter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get lowStockCount => _medicines.where((m) => m.isActive && m.isLowStock).length;

  List<MedicineModel> _filteredMedicines() {
    return _medicines.where((med) {
      // Filter by status
      if (_currentFilter == MedicineFilter.active && !med.isActive) return false;
      if (_currentFilter == MedicineFilter.completed && med.isActive) return false;
      if (_currentFilter == MedicineFilter.lowStock && (!med.isActive || !med.isLowStock)) return false;

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = med.name.toLowerCase().contains(query);
        final matchesType = med.medicineType.toLowerCase().contains(query);
        final matchesInstruction = med.instructions.toLowerCase().contains(query);
        if (!matchesName && !matchesType && !matchesInstruction) return false;
      }

      return true;
    }).toList();
  }

  void setFilter(MedicineFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  Future<void> loadMedicines(int userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _medicines = await _dbHelper.getMedicines(userId: userId);

      // Check course expiry and cancel future reminders if completed
      final now = DateTime.now();
      for (var med in _medicines) {
        if (med.isActive && med.endDate.isNotEmpty) {
          final end = DateTime.tryParse(med.endDate);
          if (end != null) {
            final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
            if (now.isAfter(endOfDay)) {
              await _notificationService.cancelMedicineReminders(med);
            }
          }
        }
      }

      await loadHistory(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load medicines: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMedicine(MedicineModel medicine) async {
    try {
      _isLoading = true;
      notifyListeners();

      final medicineId = await _dbHelper.insertMedicine(medicine);
      
      // Reload created medicine with real schedules and deterministic IDs from DB
      final createdMedicine = await _dbHelper.getMedicineById(medicineId);
      if (createdMedicine != null && createdMedicine.isActive) {
        for (var schedule in createdMedicine.schedules) {
          if (schedule.isEnabled) {
            await _notificationService.scheduleMedicineReminder(
              medicine: createdMedicine,
              schedule: schedule,
            );
          }
        }
      }

      // Reload
      _medicines = await _dbHelper.getMedicines(userId: medicine.userId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add medicine: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMedicine(MedicineModel medicine) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Cancel existing notifications for old schedules first
      if (medicine.id != null) {
        final existingMed = await _dbHelper.getMedicineById(medicine.id!);
        if (existingMed != null) {
          await _notificationService.cancelMedicineReminders(existingMed);
        }
      }

      await _dbHelper.updateMedicine(medicine);

      // Reload updated medicine from DB with new schedules and schedule reminders
      if (medicine.id != null) {
        final updatedMedicine = await _dbHelper.getMedicineById(medicine.id!);
        if (updatedMedicine != null && updatedMedicine.isActive) {
          for (var schedule in updatedMedicine.schedules) {
            if (schedule.isEnabled) {
              await _notificationService.scheduleMedicineReminder(
                medicine: updatedMedicine,
                schedule: schedule,
              );
            }
          }
        }
      }

      _medicines = await _dbHelper.getMedicines(userId: medicine.userId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update medicine: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMedicine(MedicineModel medicine) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Retrieve full medicine with schedules from DB to ensure all are cancelled
      if (medicine.id != null) {
        final existing = await _dbHelper.getMedicineById(medicine.id!);
        if (existing != null) {
          await _notificationService.cancelMedicineReminders(existing);
        }
      }
      await _notificationService.cancelMedicineReminders(medicine);

      if (medicine.id != null) {
        await _dbHelper.deleteMedicine(medicine.id!);
      }

      _medicines = await _dbHelper.getMedicines(userId: medicine.userId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete medicine: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Dose Actions: Taken, Skipped, Snooze
  Future<SmsResult?> markDoseTaken({
    required MedicineModel medicine,
    MedicineScheduleModel? schedule,
    String notes = '',
  }) async {
    final now = DateTime.now();
    final dosageText = schedule?.dosageAmount ?? medicine.dosage;
    final historyEntry = MedicineHistoryModel(
      medicineId: medicine.id!,
      scheduleId: schedule?.id,
      medicineName: medicine.name,
      dosage: dosageText,
      scheduledTime: now.toIso8601String(),
      actualTime: now.toIso8601String(),
      status: 'taken',
      notes: notes,
      createdAt: now.toIso8601String(),
    );

    // 1. Record dose in SQLite
    await _dbHelper.insertMedicineHistory(historyEntry);

    // 2. Decrement stock
    if (medicine.remainingStock > 0) {
      final updatedStock = medicine.remainingStock - 1;
      await _dbHelper.updateMedicineStock(medicine.id!, updatedStock);

      // Check low stock
      if (updatedStock <= medicine.lowStockThreshold) {
        await _notificationService.showLowStockNotification(
          medicineId: medicine.id!,
          medicineName: medicine.name,
          remainingStock: updatedStock,
        );
      }
    }

    // Check if course has ended; cancel future reminders if completed
    if (medicine.endDate.isNotEmpty) {
      final end = DateTime.tryParse(medicine.endDate);
      if (end != null) {
        final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
        if (now.isAfter(endOfDay)) {
          await _notificationService.cancelMedicineReminders(medicine);
        }
      }
    }

    // 3. Send SMS to emergency contact only AFTER medicine status is successfully updated in database
    SmsResult? smsResult;
    try {
      smsResult = await SmsService().sendTakenAlertToEmergencyContact(
        userId: medicine.userId,
        medicineId: medicine.id!,
        medicineName: medicine.name,
        dosage: dosageText,
        takenTime: now,
      );
    } catch (e) {
      debugPrint('Error triggering emergency SMS: $e');
    }

    await loadMedicines(medicine.userId);
    return smsResult;
  }

  Future<void> markDoseSkipped({
    required MedicineModel medicine,
    MedicineScheduleModel? schedule,
    String notes = '',
  }) async {
    final now = DateTime.now();
    final historyEntry = MedicineHistoryModel(
      medicineId: medicine.id!,
      scheduleId: schedule?.id,
      medicineName: medicine.name,
      dosage: schedule?.dosageAmount ?? medicine.dosage,
      scheduledTime: now.toIso8601String(),
      actualTime: now.toIso8601String(),
      status: 'skipped',
      notes: notes,
      createdAt: now.toIso8601String(),
    );

    await _dbHelper.insertMedicineHistory(historyEntry);
    await loadMedicines(medicine.userId);
  }

  Future<void> snoozeDose({
    required MedicineModel medicine,
    int? minutes,
  }) async {
    await _notificationService.snoozeReminder(
      medicineId: medicine.id!,
      medicineName: medicine.name,
      dosage: medicine.dosage,
      minutes: minutes,
    );
  }

  // Load history with optional filters
  Future<void> loadHistory(int userId, {DateTime? start, DateTime? end, String? status}) async {
    _history = await _dbHelper.getMedicineHistory(
      startDate: start,
      endDate: end,
      status: status,
    );
    notifyListeners();
  }

  // Calculate adherence rate percentage
  double calculateAdherence() {
    if (_history.isEmpty) return 100.0;
    final takenCount = _history.where((h) => h.isTaken).length;
    final totalCount = _history.where((h) => h.isTaken || h.isMissed || h.isSkipped).length;
    if (totalCount == 0) return 100.0;
    return (takenCount / totalCount) * 100.0;
  }

  // Get daily schedule items for a specific date
  List<Map<String, dynamic>> getScheduleForDate(DateTime date) {
    List<Map<String, dynamic>> items = [];
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    for (var med in _medicines) {
      if (!med.isActive) continue;
      // Check if date is within medicine start and end range
      if (dateStr.compareTo(med.startDate) < 0 || dateStr.compareTo(med.endDate) > 0) {
        continue;
      }

      for (var schedule in med.schedules) {
        if (!schedule.isEnabled) continue;

        // Check history status for this schedule on this date
        final matchingHistory = _history.where((h) {
          if (h.medicineId != med.id) return false;
          final schedDate = DateTime.tryParse(h.scheduledTime);
          if (schedDate == null) return false;
          return schedDate.year == date.year &&
                 schedDate.month == date.month &&
                 schedDate.day == date.day &&
                 (h.scheduleId == schedule.id || h.medicineName == med.name);
        }).toList();

        String status = 'pending';
        if (matchingHistory.isNotEmpty) {
          status = matchingHistory.first.status;
        } else {
          // If past today's time, mark as missed; if future, mark pending
          final now = DateTime.now();
          final parts = schedule.timeOfDay.split(':');
          final schedDateTime = DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
          if (schedDateTime.isBefore(now)) {
            status = 'missed';
          } else {
            status = 'upcoming';
          }
        }

        items.add({
          'medicine': med,
          'schedule': schedule,
          'status': status,
          'time': schedule.timeOfDay,
          'dosage': schedule.dosageAmount,
        });
      }
    }

    items.sort((a, b) => (a['time'] as String).compareTo(b['time'] as String));
    return items;
  }
}
