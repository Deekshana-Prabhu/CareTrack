class MedicineScheduleModel {
  final int? id;
  final int medicineId;
  final String timeOfDay; // "08:00"
  final int notificationId;
  final String dosageAmount; // "1 Tablet"
  final bool isEnabled;

  MedicineScheduleModel({
    this.id,
    required this.medicineId,
    required this.timeOfDay,
    required this.notificationId,
    this.dosageAmount = '1 Dose',
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicine_id': medicineId,
      'time_of_day': timeOfDay,
      'notification_id': notificationId,
      'dosage_amount': dosageAmount,
      'is_enabled': isEnabled ? 1 : 0,
    };
  }

  factory MedicineScheduleModel.fromMap(Map<String, dynamic> map) {
    return MedicineScheduleModel(
      id: map['id'] as int?,
      medicineId: (map['medicine_id'] as num).toInt(),
      timeOfDay: map['time_of_day'] as String,
      notificationId: (map['notification_id'] as num).toInt(),
      dosageAmount: map['dosage_amount'] as String? ?? '1 Dose',
      isEnabled: (map['is_enabled'] as int?) == 1,
    );
  }

  MedicineScheduleModel copyWith({
    int? id,
    int? medicineId,
    String? timeOfDay,
    int? notificationId,
    String? dosageAmount,
    bool? isEnabled,
  }) {
    return MedicineScheduleModel(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      notificationId: notificationId ?? this.notificationId,
      dosageAmount: dosageAmount ?? this.dosageAmount,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
