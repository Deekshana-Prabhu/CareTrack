class HealthRecordModel {
  final int? id;
  final int userId;
  final String recordType; // 'blood_pressure', 'blood_glucose', 'heart_rate', 'body_temperature', 'oxygen_saturation', 'weight', 'height'
  final double valuePrimary;
  final double? valueSecondary; // Diastolic BP
  final String unit; // mmHg, mg/dL, bpm, °C, %, kg, cm
  final String recordedAt; // ISO-8601 string
  final String? mealContext; // Fasting, Post-Meal, Random, Bedtime, etc.
  final String? notes;
  final String createdAt;

  HealthRecordModel({
    this.id,
    required this.userId,
    required this.recordType,
    required this.valuePrimary,
    this.valueSecondary,
    required this.unit,
    required this.recordedAt,
    this.mealContext,
    this.notes,
    required this.createdAt,
  });

  String get displayName {
    switch (recordType) {
      case 'blood_pressure':
        return 'Blood Pressure';
      case 'blood_glucose':
        return 'Blood Glucose';
      case 'heart_rate':
        return 'Heart Rate';
      case 'body_temperature':
        return 'Body Temperature';
      case 'oxygen_saturation':
        return 'Oxygen Saturation (SpO2)';
      case 'weight':
        return 'Weight';
      case 'height':
        return 'Height';
      default:
        return recordType;
    }
  }

  String get formattedValue {
    if (recordType == 'blood_pressure') {
      return '${valuePrimary.toInt()}/${valueSecondary?.toInt() ?? 0} $unit';
    } else if (recordType == 'body_temperature' || recordType == 'weight' || recordType == 'height') {
      return '${valuePrimary.toStringAsFixed(1)} $unit';
    } else {
      return '${valuePrimary.toInt()} $unit';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'record_type': recordType,
      'value_primary': valuePrimary,
      'value_secondary': valueSecondary,
      'unit': unit,
      'recorded_at': recordedAt,
      'meal_context': mealContext,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory HealthRecordModel.fromMap(Map<String, dynamic> map) {
    return HealthRecordModel(
      id: map['id'] as int?,
      userId: (map['user_id'] as num?)?.toInt() ?? 1,
      recordType: map['record_type'] as String? ?? 'blood_pressure',
      valuePrimary: (map['value_primary'] as num?)?.toDouble() ?? 0.0,
      valueSecondary: (map['value_secondary'] as num?)?.toDouble(),
      unit: map['unit'] as String? ?? '',
      recordedAt: map['recorded_at'] as String? ?? DateTime.now().toIso8601String(),
      mealContext: map['meal_context'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  HealthRecordModel copyWith({
    int? id,
    int? userId,
    String? recordType,
    double? valuePrimary,
    double? valueSecondary,
    String? unit,
    String? recordedAt,
    String? mealContext,
    String? notes,
    String? createdAt,
  }) {
    return HealthRecordModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recordType: recordType ?? this.recordType,
      valuePrimary: valuePrimary ?? this.valuePrimary,
      valueSecondary: valueSecondary ?? this.valueSecondary,
      unit: unit ?? this.unit,
      recordedAt: recordedAt ?? this.recordedAt,
      mealContext: mealContext ?? this.mealContext,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
