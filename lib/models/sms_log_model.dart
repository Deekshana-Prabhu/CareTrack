class SmsLogModel {
  final int? id;
  final int userId;
  final int medicineId;
  final String medicineName;
  final String recipientPhone;
  final String message;
  final String status; // 'SENT_DIRECT', 'SENT_TO_COMPOSER', 'FAILED'
  final String sentAt;
  final String? errorMessage;

  SmsLogModel({
    this.id,
    required this.userId,
    required this.medicineId,
    required this.medicineName,
    required this.recipientPhone,
    required this.message,
    required this.status,
    required this.sentAt,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'recipient_phone': recipientPhone,
      'message': message,
      'status': status,
      'sent_at': sentAt,
      'error_message': errorMessage,
    };
  }

  factory SmsLogModel.fromMap(Map<String, dynamic> map) {
    return SmsLogModel(
      id: map['id'] as int?,
      userId: (map['user_id'] as num?)?.toInt() ?? 1,
      medicineId: (map['medicine_id'] as num?)?.toInt() ?? 0,
      medicineName: map['medicine_name'] as String? ?? '',
      recipientPhone: map['recipient_phone'] as String? ?? '',
      message: map['message'] as String? ?? '',
      status: map['status'] as String? ?? 'SENT_TO_COMPOSER',
      sentAt: map['sent_at'] as String? ?? DateTime.now().toIso8601String(),
      errorMessage: map['error_message'] as String?,
    );
  }
}
