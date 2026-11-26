import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/user_model.dart';
import '../../models/medicine_model.dart';
import '../../models/medicine_schedule_model.dart';
import '../../models/medicine_history_model.dart';
import '../../models/health_record_model.dart';
import '../../models/appointment_model.dart';
import '../../models/sms_log_model.dart';

class DatabaseHelper {
  static const String _dbName = 'caretrack_database.db';
  static const int _dbVersion = 2;

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        height REAL NOT NULL,
        weight REAL NOT NULL,
        blood_group TEXT NOT NULL,
        medical_history TEXT,
        allergies TEXT,
        emergency_contact_name TEXT,
        emergency_contact_phone TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 2. Medicines table
    await db.execute('''
      CREATE TABLE medicines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        medicine_type TEXT NOT NULL,
        dosage TEXT NOT NULL,
        frequency TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        food_timing TEXT NOT NULL,
        instructions TEXT,
        total_stock INTEGER NOT NULL,
        remaining_stock INTEGER NOT NULL,
        low_stock_threshold INTEGER NOT NULL DEFAULT 5,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 3. Medicine schedules table
    await db.execute('''
      CREATE TABLE medicine_schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicine_id INTEGER NOT NULL,
        time_of_day TEXT NOT NULL,
        notification_id INTEGER NOT NULL,
        dosage_amount TEXT NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (medicine_id) REFERENCES medicines (id) ON DELETE CASCADE
      )
    ''');

    // 4. Medicine history table
    await db.execute('''
      CREATE TABLE medicine_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicine_id INTEGER NOT NULL,
        schedule_id INTEGER,
        medicine_name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        scheduled_time TEXT NOT NULL,
        actual_time TEXT,
        status TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (medicine_id) REFERENCES medicines (id) ON DELETE CASCADE
      )
    ''');

    // 5. Health records table
    await db.execute('''
      CREATE TABLE health_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        record_type TEXT NOT NULL,
        value_primary REAL NOT NULL,
        value_secondary REAL,
        unit TEXT NOT NULL,
        recorded_at TEXT NOT NULL,
        meal_context TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 6. App settings table
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // 7. Appointments table
    await db.execute('''
      CREATE TABLE appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        doctor_name TEXT NOT NULL,
        hospital_name TEXT NOT NULL,
        appointment_date TEXT NOT NULL,
        appointment_time TEXT NOT NULL,
        specialization TEXT NOT NULL,
        reason TEXT NOT NULL,
        notes TEXT,
        notification_id INTEGER NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 8. SMS logs table
    await db.execute('''
      CREATE TABLE sms_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        medicine_id INTEGER NOT NULL,
        medicine_name TEXT NOT NULL,
        recipient_phone TEXT NOT NULL,
        message TEXT NOT NULL,
        status TEXT NOT NULL,
        sent_at TEXT NOT NULL,
        error_message TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS appointments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          doctor_name TEXT NOT NULL,
          hospital_name TEXT NOT NULL,
          appointment_date TEXT NOT NULL,
          appointment_time TEXT NOT NULL,
          specialization TEXT NOT NULL,
          reason TEXT NOT NULL,
          notes TEXT,
          notification_id INTEGER NOT NULL,
          is_completed INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS sms_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          medicine_id INTEGER NOT NULL,
          medicine_name TEXT NOT NULL,
          recipient_phone TEXT NOT NULL,
          message TEXT NOT NULL,
          status TEXT NOT NULL,
          sent_at TEXT NOT NULL,
          error_message TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // ================= USERS CRUD =================

  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final res = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) {
      return UserModel.fromMap(res.first);
    }
    return null;
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [email.toLowerCase().trim()],
    );
    if (res.isNotEmpty) {
      return UserModel.fromMap(res.first);
    }
    return null;
  }

  Future<int> updateUser(UserModel user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<List<UserModel>> getAllUsers() async {
    final db = await database;
    final res = await db.query('users', orderBy: 'id ASC');
    return res.map((m) => UserModel.fromMap(m)).toList();
  }

  // ================= MEDICINES CRUD =================

  Future<int> insertMedicine(MedicineModel medicine) async {
    final db = await database;
    final medicineId = await db.insert('medicines', medicine.toMap());

    // Insert schedules with unique, deterministic notification IDs
    for (int i = 0; i < medicine.schedules.length; i++) {
      final schedule = medicine.schedules[i];
      final notifId = (medicineId * 100) + i + 1;
      final scheduleWithMedId = schedule.copyWith(
        medicineId: medicineId,
        notificationId: notifId,
      );
      await db.insert('medicine_schedules', scheduleWithMedId.toMap());
    }

    return medicineId;
  }

  Future<int> updateMedicine(MedicineModel medicine) async {
    final db = await database;
    final result = await db.update(
      'medicines',
      medicine.toMap(),
      where: 'id = ?',
      whereArgs: [medicine.id],
    );

    // Replace schedules with unique, deterministic notification IDs
    await db.delete('medicine_schedules', where: 'medicine_id = ?', whereArgs: [medicine.id]);
    for (int i = 0; i < medicine.schedules.length; i++) {
      final schedule = medicine.schedules[i];
      final notifId = (medicine.id! * 100) + i + 1;
      final scheduleWithMedId = schedule.copyWith(
        medicineId: medicine.id,
        notificationId: notifId,
      );
      await db.insert('medicine_schedules', scheduleWithMedId.toMap());
    }

    return result;
  }

  /// Clean test records if previously inserted into database
  Future<void> cleanTestRecords() async {
    final db = await database;
    await db.delete('medicines', where: 'id = ?', whereArgs: [9991]);
    await db.delete('medicine_schedules', where: 'medicine_id = ? OR notification_id IN (77777, 88888, 99991, 99999)', whereArgs: [9991]);
  }

  Future<int> deleteMedicine(int id) async {
    final db = await database;
    return await db.delete('medicines', where: 'id = ?', whereArgs: [id]);
  }

  Future<MedicineModel?> getMedicineById(int id) async {
    final db = await database;
    final res = await db.query('medicines', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) {
      final schedulesRes = await db.query(
        'medicine_schedules',
        where: 'medicine_id = ?',
        whereArgs: [id],
      );
      final schedules = schedulesRes.map((s) => MedicineScheduleModel.fromMap(s)).toList();
      return MedicineModel.fromMap(res.first, schedules: schedules);
    }
    return null;
  }

  Future<List<MedicineModel>> getMedicines({
    int? userId,
    String? searchQuery,
    bool? activeOnly,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClause += 'user_id = ?';
      whereArgs.add(userId);
    }

    if (activeOnly != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'is_active = ?';
      whereArgs.add(activeOnly ? 1 : 0);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '(name LIKE ? OR medicine_type LIKE ? OR instructions LIKE ?)';
      final queryParam = '%$searchQuery%';
      whereArgs.addAll([queryParam, queryParam, queryParam]);
    }

    final res = await db.query(
      'medicines',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name ASC',
    );

    List<MedicineModel> medicines = [];
    for (var map in res) {
      final id = map['id'] as int;
      final schedulesRes = await db.query(
        'medicine_schedules',
        where: 'medicine_id = ?',
        whereArgs: [id],
      );
      final schedules = schedulesRes.map((s) => MedicineScheduleModel.fromMap(s)).toList();
      medicines.add(MedicineModel.fromMap(map, schedules: schedules));
    }

    return medicines;
  }

  Future<int> updateMedicineStock(int medicineId, int newStock) async {
    final db = await database;
    return await db.update(
      'medicines',
      {
        'remaining_stock': newStock,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [medicineId],
    );
  }

  Future<List<MedicineScheduleModel>> getAllActiveSchedules() async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT s.* FROM medicine_schedules s
      JOIN medicines m ON s.medicine_id = m.id
      WHERE m.is_active = 1 AND s.is_enabled = 1
    ''');
    return res.map((s) => MedicineScheduleModel.fromMap(s)).toList();
  }

  // ================= MEDICINE HISTORY CRUD =================

  Future<int> insertMedicineHistory(MedicineHistoryModel history) async {
    final db = await database;
    return await db.insert('medicine_history', history.toMap());
  }

  Future<int> updateMedicineHistory(MedicineHistoryModel history) async {
    final db = await database;
    return await db.update(
      'medicine_history',
      history.toMap(),
      where: 'id = ?',
      whereArgs: [history.id],
    );
  }

  Future<List<MedicineHistoryModel>> getMedicineHistory({
    int? medicineId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (medicineId != null) {
      whereClause += 'medicine_id = ?';
      whereArgs.add(medicineId);
    }

    if (startDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'scheduled_time >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'scheduled_time <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    if (status != null && status.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'status = ?';
      whereArgs.add(status.toLowerCase());
    }

    final res = await db.query(
      'medicine_history',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'scheduled_time DESC',
    );

    return res.map((m) => MedicineHistoryModel.fromMap(m)).toList();
  }

  // ================= HEALTH RECORDS CRUD =================

  Future<int> insertHealthRecord(HealthRecordModel record) async {
    final db = await database;
    return await db.insert('health_records', record.toMap());
  }

  Future<int> updateHealthRecord(HealthRecordModel record) async {
    final db = await database;
    return await db.update(
      'health_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteHealthRecord(int id) async {
    final db = await database;
    return await db.delete('health_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<HealthRecordModel?> getHealthRecordById(int id) async {
    final db = await database;
    final res = await db.query('health_records', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) {
      return HealthRecordModel.fromMap(res.first);
    }
    return null;
  }

  Future<List<HealthRecordModel>> getHealthRecords({
    int? userId,
    String? recordType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClause += 'user_id = ?';
      whereArgs.add(userId);
    }

    if (recordType != null && recordType.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'record_type = ?';
      whereArgs.add(recordType);
    }

    if (startDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'recorded_at >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'recorded_at <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final res = await db.query(
      'health_records',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'recorded_at DESC',
    );

    return res.map((m) => HealthRecordModel.fromMap(m)).toList();
  }

  Future<Map<String, HealthRecordModel>> getLatestHealthRecords(int userId) async {
    final db = await database;
    final types = [
      'blood_pressure',
      'blood_glucose',
      'heart_rate',
      'body_temperature',
      'oxygen_saturation',
      'weight',
      'height',
    ];

    Map<String, HealthRecordModel> latest = {};
    for (var type in types) {
      final res = await db.query(
        'health_records',
        where: 'user_id = ? AND record_type = ?',
        whereArgs: [userId, type],
        orderBy: 'recorded_at DESC',
        limit: 1,
      );
      if (res.isNotEmpty) {
        latest[type] = HealthRecordModel.fromMap(res.first);
      }
    }
    return latest;
  }

  // ================= APP SETTINGS CRUD =================

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final res = await db.query('app_settings', where: 'key = ?', whereArgs: [key]);
    if (res.isNotEmpty) {
      return res.first['value'] as String?;
    }
    return null;
  }

  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final res = await db.query('app_settings');
    Map<String, String> map = {};
    for (var row in res) {
      map[row['key'] as String] = row['value'] as String;
    }
    return map;
  }

  // ================= APPOINTMENTS CRUD =================

  Future<int> insertAppointment(AppointmentModel appointment) async {
    final db = await database;
    return await db.insert('appointments', appointment.toMap());
  }

  Future<int> updateAppointment(AppointmentModel appointment) async {
    final db = await database;
    return await db.update(
      'appointments',
      appointment.toMap(),
      where: 'id = ?',
      whereArgs: [appointment.id],
    );
  }

  Future<int> deleteAppointment(int id) async {
    final db = await database;
    return await db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }

  Future<AppointmentModel?> getAppointmentById(int id) async {
    final db = await database;
    final res = await db.query('appointments', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) {
      return AppointmentModel.fromMap(res.first);
    }
    return null;
  }

  Future<List<AppointmentModel>> getAppointments({int? userId, bool? upcomingOnly}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClause += 'user_id = ?';
      whereArgs.add(userId);
    }

    if (upcomingOnly == true) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'is_completed = 0';
    }

    final res = await db.query(
      'appointments',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'appointment_date ASC, appointment_time ASC',
    );

    return res.map((m) => AppointmentModel.fromMap(m)).toList();
  }

  Future<AppointmentModel?> getNextUpcomingAppointment(int userId) async {
    final list = await getAppointments(userId: userId, upcomingOnly: true);
    final upcoming = list.where((a) => a.isUpcoming).toList();
    if (upcoming.isNotEmpty) {
      return upcoming.first;
    }
    return null;
  }

  // ================= SMS LOGS CRUD =================

  Future<int> insertSmsLog(SmsLogModel log) async {
    final db = await database;
    return await db.insert('sms_logs', log.toMap());
  }

  Future<List<SmsLogModel>> getSmsLogs({int? userId, int? medicineId}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClause += 'user_id = ?';
      whereArgs.add(userId);
    }

    if (medicineId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'medicine_id = ?';
      whereArgs.add(medicineId);
    }

    final res = await db.query(
      'sms_logs',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'sent_at DESC',
    );

    return res.map((m) => SmsLogModel.fromMap(m)).toList();
  }

  // Prevent duplicate SMS within a specific duration (e.g. 5 minutes for the same medicine dose)
  Future<bool> hasSmsSentRecently(int medicineId, Duration duration) async {
    final db = await database;
    final threshold = DateTime.now().subtract(duration).toIso8601String();
    final res = await db.query(
      'sms_logs',
      where: 'medicine_id = ? AND sent_at >= ? AND (status = ? OR status = ?)',
      whereArgs: [medicineId, threshold, 'SENT_DIRECT', 'SENT_TO_COMPOSER'],
      limit: 1,
    );
    return res.isNotEmpty;
  }
}
