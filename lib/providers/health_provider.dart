import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';
import '../models/health_record_model.dart';

enum HealthTimeRange { daily, weekly, monthly, all }

class HealthStats {
  final double average;
  final double min;
  final double max;
  final double? secondaryAverage;
  final double? secondaryMin;
  final double? secondaryMax;
  final int count;
  final String trendSummary;

  const HealthStats({
    required this.average,
    required this.min,
    required this.max,
    this.secondaryAverage,
    this.secondaryMin,
    this.secondaryMax,
    required this.count,
    required this.trendSummary,
  });
}

class HealthProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<HealthRecordModel> _records = [];
  Map<String, HealthRecordModel> _latestRecords = {};
  HealthTimeRange _selectedTimeRange = HealthTimeRange.weekly;
  String _selectedRecordType = 'blood_pressure';
  bool _isLoading = false;
  String? _errorMessage;

  List<HealthRecordModel> get records => _records;
  Map<String, HealthRecordModel> get latestRecords => _latestRecords;
  HealthTimeRange get selectedTimeRange => _selectedTimeRange;
  String get selectedRecordType => _selectedRecordType;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setRecordType(String type) {
    _selectedRecordType = type;
    notifyListeners();
  }

  void setTimeRange(HealthTimeRange range) {
    _selectedTimeRange = range;
    notifyListeners();
  }

  Future<void> loadHealthData(int userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _records = await _dbHelper.getHealthRecords(userId: userId);
      _latestRecords = await _dbHelper.getLatestHealthRecords(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load health records: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addRecord(HealthRecordModel record) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _dbHelper.insertHealthRecord(record);
      await loadHealthData(record.userId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add health record: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRecord(HealthRecordModel record) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _dbHelper.updateHealthRecord(record);
      await loadHealthData(record.userId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update health record: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRecord(HealthRecordModel record) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (record.id != null) {
        await _dbHelper.deleteHealthRecord(record.id!);
      }
      await loadHealthData(record.userId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete record: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Filtered records by record type and time range
  List<HealthRecordModel> getFilteredRecords({String? overrideType, HealthTimeRange? overrideRange}) {
    final type = overrideType ?? _selectedRecordType;
    final range = overrideRange ?? _selectedTimeRange;
    final now = DateTime.now();

    DateTime? cutoff;
    switch (range) {
      case HealthTimeRange.daily:
        cutoff = DateTime(now.year, now.month, now.day);
        break;
      case HealthTimeRange.weekly:
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case HealthTimeRange.monthly:
        cutoff = now.subtract(const Duration(days: 30));
        break;
      case HealthTimeRange.all:
        cutoff = null;
        break;
    }

    return _records.where((r) {
      if (r.recordType != type) return false;
      if (cutoff != null) {
        final date = DateTime.tryParse(r.recordedAt);
        if (date == null || date.isBefore(cutoff)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
  }

  // Calculate statistics (average, min, max, trend)
  HealthStats calculateStats({String? overrideType, HealthTimeRange? overrideRange}) {
    final list = getFilteredRecords(overrideType: overrideType, overrideRange: overrideRange);
    if (list.isEmpty) {
      return const HealthStats(
        average: 0,
        min: 0,
        max: 0,
        count: 0,
        trendSummary: 'No data available for this range',
      );
    }

    double sum = 0;
    double min = list.first.valuePrimary;
    double max = list.first.valuePrimary;

    double secSum = 0;
    double? secMin = list.first.valueSecondary;
    double? secMax = list.first.valueSecondary;
    bool hasSecondary = list.first.valueSecondary != null;

    for (var r in list) {
      sum += r.valuePrimary;
      if (r.valuePrimary < min) min = r.valuePrimary;
      if (r.valuePrimary > max) max = r.valuePrimary;

      if (r.valueSecondary != null) {
        secSum += r.valueSecondary!;
        if (secMin == null || r.valueSecondary! < secMin) secMin = r.valueSecondary;
        if (secMax == null || r.valueSecondary! > secMax) secMax = r.valueSecondary;
      }
    }

    final avg = sum / list.length;
    final secAvg = hasSecondary ? (secSum / list.length) : null;

    // Trend summary comparison between first half and second half
    String trend = 'Stable';
    if (list.length >= 2) {
      final firstVal = list.first.valuePrimary;
      final lastVal = list.last.valuePrimary;
      final diff = lastVal - firstVal;
      final pct = (diff / firstVal).abs() * 100;
      if (diff > 0 && pct > 3) {
        trend = 'Upward Trend (+${diff.toStringAsFixed(1)})';
      } else if (diff < 0 && pct > 3) {
        trend = 'Downward Trend (${diff.toStringAsFixed(1)})';
      } else {
        trend = 'Stable reading variation';
      }
    }

    return HealthStats(
      average: avg,
      min: min,
      max: max,
      secondaryAverage: secAvg,
      secondaryMin: secMin,
      secondaryMax: secMax,
      count: list.length,
      trendSummary: trend,
    );
  }
}
