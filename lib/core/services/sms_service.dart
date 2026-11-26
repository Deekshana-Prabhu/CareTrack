import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database/database_helper.dart';
import '../../models/sms_log_model.dart';

class SmsResult {
  final bool success;
  final String message;
  final String status; // 'SENT_DIRECT', 'SENT_TO_COMPOSER', 'FAILED', 'NO_CONTACT', 'DUPLICATE_SKIPPED'
  final String? recipientPhone;

  const SmsResult({
    required this.success,
    required this.message,
    required this.status,
    this.recipientPhone,
  });
}

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Format the required alert message
  static String formatAlertMessage({
    required String medicineName,
    required String dosage,
    required DateTime takenTime,
  }) {
    final timeStr = DateFormat('hh:mm a').format(takenTime);
    final dateStr = DateFormat('yyyy-MM-dd').format(takenTime);

    return 'CareTrack Alert: The patient has taken their scheduled medicine.\n'
        'Medicine: $medicineName\n'
        'Dosage: $dosage\n'
        'Time: $timeStr\n'
        'Date: $dateStr';
  }

  // Trigger emergency contact notification
  Future<SmsResult> sendTakenAlertToEmergencyContact({
    required int userId,
    required int medicineId,
    required String medicineName,
    required String dosage,
    DateTime? takenTime,
  }) async {
    final effectiveTime = takenTime ?? DateTime.now();

    try {
      // 1. Prevent duplicate SMS for the same medicine dose within 10 minutes
      final isDuplicate = await _dbHelper.hasSmsSentRecently(
        medicineId,
        const Duration(minutes: 10),
      );

      if (isDuplicate) {
        debugPrint('Duplicate emergency SMS prevented for medicineId: $medicineId');
        return const SmsResult(
          success: false,
          message: 'An alert for this medicine was already sent recently.',
          status: 'DUPLICATE_SKIPPED',
        );
      }

      // 2. Fetch user profile and emergency contact
      final user = await _dbHelper.getUserById(userId);
      if (user == null) {
        return const SmsResult(
          success: false,
          message: 'User profile not found.',
          status: 'FAILED',
        );
      }

      final phone = user.emergencyContactPhone.trim();
      final contactName = user.emergencyContactName.trim();

      // 3. Validate phone number
      if (phone.isEmpty) {
        return const SmsResult(
          success: false,
          message: 'No emergency contact phone number registered in profile.',
          status: 'NO_CONTACT',
        );
      }

      final cleanedPhone = phone.replaceAll(RegExp(r'[^\+0-9]'), '');
      if (cleanedPhone.length < 5) {
        return SmsResult(
          success: false,
          message: 'Emergency contact phone number ($phone) is invalid.',
          status: 'NO_CONTACT',
          recipientPhone: phone,
        );
      }

      // 4. Construct SMS message
      final message = formatAlertMessage(
        medicineName: medicineName,
        dosage: dosage,
        takenTime: effectiveTime,
      );

      // 5. Launch SMS Composer / Intent
      final smsUri = Uri(
        scheme: 'sms',
        path: cleanedPhone,
        queryParameters: <String, String>{
          'body': message,
        },
      );

      bool launched = false;
      String? errorMessage;
      String status = 'SENT_TO_COMPOSER';

      try {
        if (await canLaunchUrl(smsUri)) {
          launched = await launchUrl(smsUri, mode: LaunchMode.externalApplication);
        } else {
          // Fallback with smsto:
          final smstoUri = Uri.parse('smsto:$cleanedPhone?body=${Uri.encodeComponent(message)}');
          if (await canLaunchUrl(smstoUri)) {
            launched = await launchUrl(smstoUri, mode: LaunchMode.externalApplication);
          } else {
            errorMessage = 'Could not open device SMS messaging application.';
            status = 'FAILED';
          }
        }
      } catch (e) {
        errorMessage = e.toString();
        status = 'FAILED';
      }

      // 6. Record SMS delivery attempt in local SQLite database
      final smsLog = SmsLogModel(
        userId: userId,
        medicineId: medicineId,
        medicineName: medicineName,
        recipientPhone: cleanedPhone,
        message: message,
        status: status,
        sentAt: effectiveTime.toIso8601String(),
        errorMessage: errorMessage,
      );
      await _dbHelper.insertSmsLog(smsLog);

      if (launched) {
        return SmsResult(
          success: true,
          message: 'Emergency SMS prepared for ${contactName.isNotEmpty ? contactName : phone}. Please tap Send in your SMS app.',
          status: 'SENT_TO_COMPOSER',
          recipientPhone: cleanedPhone,
        );
      } else {
        return SmsResult(
          success: false,
          message: errorMessage ?? 'Failed to open SMS composer for emergency contact.',
          status: 'FAILED',
          recipientPhone: cleanedPhone,
        );
      }
    } catch (e) {
      debugPrint('Error sending emergency SMS: $e');
      return SmsResult(
        success: false,
        message: 'Error sending SMS: $e',
        status: 'FAILED',
      );
    }
  }
}
