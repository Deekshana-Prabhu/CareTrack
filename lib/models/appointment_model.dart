class AppointmentModel {
  final int? id;
  final int userId;
  final String doctorName;
  final String hospitalName;
  final String appointmentDate; // YYYY-MM-DD
  final String appointmentTime; // HH:mm
  final String specialization;
  final String reason;
  final String notes;
  final int notificationId;
  final bool isCompleted;
  final String createdAt;

  AppointmentModel({
    this.id,
    required this.userId,
    required this.doctorName,
    required this.hospitalName,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.specialization,
    required this.reason,
    this.notes = '',
    required this.notificationId,
    this.isCompleted = false,
    required this.createdAt,
  });

  DateTime get appointmentDateTime {
    try {
      final dateParts = appointmentDate.split('-');
      final timeParts = appointmentTime.split(':');
      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (_) {
      return DateTime.now();
    }
  }

  bool get isUpcoming {
    if (isCompleted) return false;
    return appointmentDateTime.isAfter(DateTime.now());
  }

  int get remainingDays {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final apptDay = DateTime(
      appointmentDateTime.year,
      appointmentDateTime.month,
      appointmentDateTime.day,
    );
    return apptDay.difference(today).inDays;
  }

  String get countdownText {
    if (isCompleted) return 'Completed';
    final now = DateTime.now();
    final diff = appointmentDateTime.difference(now);

    if (diff.isNegative) return 'Past Appointment';

    final days = remainingDays;
    if (days == 0) {
      final hours = diff.inHours;
      if (hours > 0) return 'Today (in $hours hrs)';
      final mins = diff.inMinutes;
      return 'Today (in $mins mins)';
    } else if (days == 1) {
      return 'Tomorrow';
    } else {
      return 'In $days days';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'doctor_name': doctorName,
      'hospital_name': hospitalName,
      'appointment_date': appointmentDate,
      'appointment_time': appointmentTime,
      'specialization': specialization,
      'reason': reason,
      'notes': notes,
      'notification_id': notificationId,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: map['id'] as int?,
      userId: (map['user_id'] as num?)?.toInt() ?? 1,
      doctorName: map['doctor_name'] as String? ?? '',
      hospitalName: map['hospital_name'] as String? ?? '',
      appointmentDate: map['appointment_date'] as String? ?? '',
      appointmentTime: map['appointment_time'] as String? ?? '',
      specialization: map['specialization'] as String? ?? 'General Physician',
      reason: map['reason'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      notificationId: (map['notification_id'] as num?)?.toInt() ?? 0,
      isCompleted: (map['is_completed'] as int?) == 1,
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  AppointmentModel copyWith({
    int? id,
    int? userId,
    String? doctorName,
    String? hospitalName,
    String? appointmentDate,
    String? appointmentTime,
    String? specialization,
    String? reason,
    String? notes,
    int? notificationId,
    bool? isCompleted,
    String? createdAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      doctorName: doctorName ?? this.doctorName,
      hospitalName: hospitalName ?? this.hospitalName,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      specialization: specialization ?? this.specialization,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      notificationId: notificationId ?? this.notificationId,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
