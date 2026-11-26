import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:caretrack/core/constants/health_reference.dart';
import 'package:caretrack/core/services/security_service.dart';
import 'package:caretrack/core/utils/validators.dart';
import 'package:caretrack/core/utils/date_utils.dart';
import 'package:caretrack/models/user_model.dart';
import 'package:caretrack/models/medicine_model.dart';
import 'package:caretrack/models/medicine_schedule_model.dart';
import 'package:caretrack/models/medicine_history_model.dart';
import 'package:caretrack/models/health_record_model.dart';
import 'package:caretrack/models/appointment_model.dart';
import 'package:caretrack/models/sms_log_model.dart';
import 'package:caretrack/core/services/sms_service.dart';
import 'package:caretrack/core/services/notification_service.dart';

void main() {
  group('SecurityService Tests', () {
    test('Password hashing produces consistent SHA-256 with salt', () {
      const password = 'TestSecretPassword123';
      final hash1 = SecurityService.hashPassword(password);
      final hash2 = SecurityService.hashPassword(password);
      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64)); // SHA-256 is 64 hex characters
    });

    test('Password verification correctly validates correct and incorrect passwords', () {
      const password = 'MySecurePassWord!';
      final hash = SecurityService.hashPassword(password);
      expect(SecurityService.verifyPassword(password, hash), isTrue);
      expect(SecurityService.verifyPassword('WrongPassword', hash), isFalse);
    });
  });

  group('HealthReference Evaluations Tests', () {
    test('Blood Pressure Normal Evaluation (<120 / <80)', () {
      final result = HealthReference.evaluateBloodPressure(115, 75);
      expect(result.status, equals('Normal'));
    });

    test('Blood Pressure Elevated Evaluation (125 / 78)', () {
      final result = HealthReference.evaluateBloodPressure(125, 78);
      expect(result.status, equals('Elevated'));
    });

    test('Blood Pressure Stage 2 Hypertension Evaluation (145 / 95)', () {
      final result = HealthReference.evaluateBloodPressure(145, 95);
      expect(result.status, equals('Stage 2 Hypertension'));
    });

    test('Blood Glucose Fasting Normal (70 - 99 mg/dL)', () {
      final result = HealthReference.evaluateBloodGlucose(85, context: 'Fasting');
      expect(result.status, equals('Normal Fasting'));
    });

    test('Blood Glucose Fasting High (>= 126 mg/dL)', () {
      final result = HealthReference.evaluateBloodGlucose(135, context: 'Fasting');
      expect(result.status, equals('High Fasting'));
    });

    test('Heart Rate Normal (60 - 100 bpm)', () {
      final result = HealthReference.evaluateHeartRate(72);
      expect(result.status, equals('Normal'));
    });

    test('Heart Rate Tachycardia (> 100 bpm)', () {
      final result = HealthReference.evaluateHeartRate(110);
      expect(result.status, equals('High (Tachycardia)'));
    });

    test('SpO2 Normal (>= 95%)', () {
      final result = HealthReference.evaluateSpO2(98);
      expect(result.status, equals('Normal'));
    });

    test('SpO2 Hypoxia (< 90%)', () {
      final result = HealthReference.evaluateSpO2(88);
      expect(result.status, equals('Critical Hypoxia'));
    });

    test('BMI Calculation & Evaluation', () {
      // 70 kg, 175 cm => 70 / (1.75 * 1.75) = 22.857
      final bmi = HealthReference.calculateBMI(70, 175);
      expect(bmi, closeTo(22.86, 0.05));
      final eval = HealthReference.evaluateBMI(bmi);
      expect(eval.status, equals('Normal Weight'));
    });
  });

  group('Validators Tests', () {
    test('Email validator accepts valid emails and rejects invalid ones', () {
      expect(Validators.validateEmail('user@test.com'), isNull);
      expect(Validators.validateEmail('not-an-email'), isNotNull);
      expect(Validators.validateEmail(''), isNotNull);
    });

    test('Password validator requires at least 6 characters', () {
      expect(Validators.validatePassword('123456'), isNull);
      expect(Validators.validatePassword('12345'), isNotNull);
      expect(Validators.validatePassword(''), isNotNull);
    });

    test('Number validator checks min and max', () {
      expect(Validators.validateNumber('35', 'Age', min: 1, max: 120), isNull);
      expect(Validators.validateNumber('0', 'Age', min: 1, max: 120), isNotNull);
      expect(Validators.validateNumber('150', 'Age', min: 1, max: 120), isNotNull);
    });
  });

  group('Models Serialization Tests', () {
    test('UserModel serialization and deserialization', () {
      final user = UserModel(
        id: 1,
        name: 'Jane Doe',
        email: 'jane@example.com',
        passwordHash: 'hash123',
        age: 30,
        gender: 'Female',
        height: 165.0,
        weight: 60.0,
        bloodGroup: 'O+',
        medicalHistory: 'None',
        allergies: 'Penicillin',
        emergencyContactName: 'John Doe',
        emergencyContactPhone: '+1234567890',
        createdAt: '2026-01-01T00:00:00',
        updatedAt: '2026-01-01T00:00:00',
      );

      final map = user.toMap();
      final fromMap = UserModel.fromMap(map);

      expect(fromMap.id, equals(user.id));
      expect(fromMap.name, equals(user.name));
      expect(fromMap.email, equals(user.email));
      expect(fromMap.bloodGroup, equals('O+'));
      expect(fromMap.allergies, equals('Penicillin'));
    });

    test('MedicineModel and low stock detection', () {
      final med = MedicineModel(
        id: 1,
        userId: 1,
        name: 'Aspirin',
        medicineType: 'Tablet',
        dosage: '81 mg',
        frequency: 'Once daily',
        startDate: '2026-01-01',
        endDate: '2026-12-31',
        foodTiming: 'After food',
        instructions: 'Take in the morning',
        totalStock: 30,
        remainingStock: 4,
        lowStockThreshold: 5,
        isActive: true,
        createdAt: '2026-01-01',
        updatedAt: '2026-01-01',
        schedules: [
          MedicineScheduleModel(
            medicineId: 1,
            timeOfDay: '08:00',
            notificationId: 101,
          ),
        ],
      );

      expect(med.isLowStock, isTrue);
      final map = med.toMap();
      final fromMap = MedicineModel.fromMap(map, schedules: med.schedules);
      expect(fromMap.name, equals('Aspirin'));
      expect(fromMap.schedules.length, equals(1));
    });

    test('MedicineHistoryModel status helpers', () {
      final history = MedicineHistoryModel(
        medicineId: 1,
        medicineName: 'Aspirin',
        dosage: '81 mg',
        scheduledTime: '2026-01-01T08:00:00',
        status: 'taken',
        createdAt: '2026-01-01T08:05:00',
      );

      expect(history.isTaken, isTrue);
      expect(history.isSkipped, isFalse);
      expect(history.isMissed, isFalse);
    });

    test('HealthRecordModel formattedValue', () {
      final bp = HealthRecordModel(
        userId: 1,
        recordType: 'blood_pressure',
        valuePrimary: 120,
        valueSecondary: 80,
        unit: 'mmHg',
        recordedAt: '2026-01-01T08:00:00',
        createdAt: '2026-01-01T08:00:00',
      );

      expect(bp.formattedValue, equals('120/80 mmHg'));
      expect(bp.displayName, equals('Blood Pressure'));
    });
  });

  group('DateUtils Tests', () {
    test('formatTimeString parses HH:mm properly', () {
      final formatted = AppDateUtils.formatTimeString('08:30');
      expect(formatted.toLowerCase(), contains('8:30'));
    });
  });

  group('AppointmentModel Tests', () {
    test('AppointmentModel serialization and countdown text', () {
      final futureDate = DateTime.now().add(const Duration(days: 3));
      final dateStr = '${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}';

      final appt = AppointmentModel(
        id: 1,
        userId: 1,
        doctorName: 'Sarah Jenkins',
        hospitalName: 'City Hospital',
        appointmentDate: dateStr,
        appointmentTime: '14:30',
        specialization: 'Cardiologist',
        reason: 'Annual heart checkup',
        notificationId: 888,
        createdAt: DateTime.now().toIso8601String(),
      );

      final map = appt.toMap();
      final fromMap = AppointmentModel.fromMap(map);

      expect(fromMap.doctorName, equals('Sarah Jenkins'));
      expect(fromMap.hospitalName, equals('City Hospital'));
      expect(fromMap.specialization, equals('Cardiologist'));
      expect(fromMap.isUpcoming, isTrue);
      expect(fromMap.countdownText, contains('In 3 days'));
    });
  });

  group('SmsService & Alert Format Tests', () {
    test('formatAlertMessage produces exact expected format', () {
      final takenTime = DateTime(2026, 11, 23, 14, 30);
      final message = SmsService.formatAlertMessage(
        medicineName: 'Amoxicillin',
        dosage: '500 mg',
        takenTime: takenTime,
      );

      expect(message, contains('CareTrack Alert: The patient has taken their scheduled medicine.'));
      expect(message, contains('Medicine: Amoxicillin'));
      expect(message, contains('Dosage: 500 mg'));
      expect(message, contains('Time: 02:30 PM'));
      expect(message, contains('Date: 2026-11-23'));
    });

    test('SmsLogModel serialization', () {
      final log = SmsLogModel(
        id: 1,
        userId: 1,
        medicineId: 10,
        medicineName: 'Metformin',
        recipientPhone: '+1234567890',
        message: 'CareTrack Alert...',
        status: 'SENT_TO_COMPOSER',
        sentAt: '2026-11-23T14:30:00',
      );

      final map = log.toMap();
      final fromMap = SmsLogModel.fromMap(map);
      expect(fromMap.medicineName, equals('Metformin'));
      expect(fromMap.recipientPhone, equals('+1234567890'));
      expect(fromMap.status, equals('SENT_TO_COMPOSER'));
    });
  });

  group('NotificationService Configuration & Scheduling Tests', () {
    setUpAll(() {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    });

    test('Notification channels and ApplicationId are configured correctly', () {
      expect(NotificationService.expectedApplicationId, equals('com.caretrack.caretrack'));
      expect(NotificationService.channelId, equals('caretrack_medicine_v5'));
      expect(NotificationService.appointmentChannelId, equals('caretrack_appointment_v5'));
      expect(NotificationService.lowStockChannelId, equals('caretrack_low_stock_v5'));
    });

    test('calculateNextScheduleDateTime returns null for expired medicine course', () {
      final service = NotificationService();
      final expiredMed = MedicineModel(
        id: 1,
        userId: 1,
        name: 'Amoxicillin',
        medicineType: 'Capsule',
        dosage: '500 mg',
        frequency: 'Three times daily',
        startDate: '2020-01-01',
        endDate: '2020-01-07',
        foodTiming: 'After food',
        totalStock: 20,
        remainingStock: 20,
        createdAt: '2020-01-01',
        updatedAt: '2020-01-01',
      );
      final schedule = MedicineScheduleModel(
        medicineId: 1,
        timeOfDay: '08:00',
        notificationId: 101,
      );

      final next = service.calculateNextScheduleDateTime(
        medicine: expiredMed,
        schedule: schedule,
      );
      expect(next, isNull);
    });

    test('calculateNextScheduleDateTime schedules future start date correctly', () {
      final service = NotificationService();
      final futureMed = MedicineModel(
        id: 2,
        userId: 1,
        name: 'Metformin',
        medicineType: 'Tablet',
        dosage: '500 mg',
        frequency: 'Twice daily',
        startDate: '2030-05-15',
        endDate: '2030-06-15',
        foodTiming: 'With food',
        totalStock: 60,
        remainingStock: 60,
        createdAt: '2026-11-23',
        updatedAt: '2026-11-23',
      );
      final schedule = MedicineScheduleModel(
        medicineId: 2,
        timeOfDay: '08:00',
        notificationId: 201,
      );

      final next = service.calculateNextScheduleDateTime(
        medicine: futureMed,
        schedule: schedule,
      );
      expect(next, isNotNull);
      expect(next!.year, equals(2030));
      expect(next.month, equals(5));
      expect(next.day, equals(15));
      expect(next.hour, equals(8));
      expect(next.minute, equals(0));
    });

    test('calculateNextScheduleDateTime never schedules in the past', () {
      final service = NotificationService();
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final endStr = '${now.year + 1}-12-31';

      final activeMed = MedicineModel(
        id: 3,
        userId: 1,
        name: 'Atorvastatin',
        medicineType: 'Tablet',
        dosage: '20 mg',
        frequency: 'Once daily',
        startDate: todayStr,
        endDate: endStr,
        foodTiming: 'Before food',
        totalStock: 30,
        remainingStock: 30,
        createdAt: todayStr,
        updatedAt: todayStr,
      );
      final schedule = MedicineScheduleModel(
        medicineId: 3,
        timeOfDay: '00:01', // 1 minute past midnight, in the past for today
        notificationId: 301,
      );

      final next = service.calculateNextScheduleDateTime(
        medicine: activeMed,
        schedule: schedule,
      );
      expect(next, isNotNull);
      expect(next!.isAfter(tz.TZDateTime.now(tz.local)), isTrue);
    });
  });
}
