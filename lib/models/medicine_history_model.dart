class MedicineHistoryModel {
  final int? id;
  final int medicineId;
  final int? scheduleId;
  final String medicineName;
  final String dosage;
  final String scheduledTime; // ISO-8601 string or YYYY-MM-DDTHH:mm:ss
  final String? actualTime;   // ISO-8601 string or null
  final String status;       // 'taken', 'skipped', 'missed', 'snoozed'
  final String notes;
  final String createdAt;

  MedicineHistoryModel({
    this.id,
    required this.medicineId,
    this.scheduleId,
    required this.medicineName,
    required this.dosage,
    required this.scheduledTime,
    this.actualTime,
    required this.status,
    this.notes = '',
    required this.createdAt,
  });

  bool get isTaken => status.toLowerCase() == 'taken';
  bool get isSkipped => status.toLowerCase() == 'skipped';
  bool get isMissed => status.toLowerCase() == 'missed';
  bool get isSnoozed => status.toLowerCase() == 'snoozed';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicine_id': medicineId,
      'schedule_id': scheduleId,
      'medicine_name': medicineName,
      'dosage': dosage,
      'scheduled_time': scheduledTime,
      'actual_time': actualTime,
      'status': status,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory MedicineHistoryModel.fromMap(Map<String, dynamic> map) {
    return MedicineHistoryModel(
      id: map['id'] as int?,
      medicineId: (map['medicine_id'] as num).toInt(),
      scheduleId: map['schedule_id'] as int?,
      medicineName: map['medicine_name'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      scheduledTime: map['scheduled_time'] as String? ?? '',
      actualTime: map['actual_time'] as String?,
      status: map['status'] as String? ?? 'missed',
      notes: map['notes'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  MedicineHistoryModel copyWith({
    int? id,
    int? medicineId,
    int? scheduleId,
    String? medicineName,
    String? dosage,
    String? scheduledTime,
    String? actualTime,
    String? status,
    String? notes,
    String? createdAt,
  }) {
    return MedicineHistoryModel(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      scheduleId: scheduleId ?? this.scheduleId,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      actualTime: actualTime ?? this.actualTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
