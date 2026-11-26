import 'medicine_schedule_model.dart';

class MedicineModel {
  final int? id;
  final int userId;
  final String name;
  final String medicineType; // Tablet, Capsule, Syrup, Injection, Drops, Inhaler, Ointment, Other
  final String dosage; // e.g. "500 mg", "10 ml"
  final String frequency; // Once daily, Twice daily, Three times daily, Every 8 hours, As needed
  final String startDate; // YYYY-MM-DD
  final String endDate; // YYYY-MM-DD
  final String foodTiming; // Before food, After food, With food
  final String instructions;
  final int totalStock;
  final int remainingStock;
  final int lowStockThreshold;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final List<MedicineScheduleModel> schedules;

  MedicineModel({
    this.id,
    required this.userId,
    required this.name,
    required this.medicineType,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    required this.endDate,
    required this.foodTiming,
    this.instructions = '',
    required this.totalStock,
    required this.remainingStock,
    this.lowStockThreshold = 5,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.schedules = const [],
  });

  bool get isLowStock => remainingStock <= lowStockThreshold;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'medicine_type': medicineType,
      'dosage': dosage,
      'frequency': frequency,
      'start_date': startDate,
      'end_date': endDate,
      'food_timing': foodTiming,
      'instructions': instructions,
      'total_stock': totalStock,
      'remaining_stock': remainingStock,
      'low_stock_threshold': lowStockThreshold,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory MedicineModel.fromMap(Map<String, dynamic> map, {List<MedicineScheduleModel>? schedules}) {
    return MedicineModel(
      id: map['id'] as int?,
      userId: (map['user_id'] as num?)?.toInt() ?? 1,
      name: map['name'] as String? ?? '',
      medicineType: map['medicine_type'] as String? ?? 'Tablet',
      dosage: map['dosage'] as String? ?? '',
      frequency: map['frequency'] as String? ?? 'Once daily',
      startDate: map['start_date'] as String? ?? '',
      endDate: map['end_date'] as String? ?? '',
      foodTiming: map['food_timing'] as String? ?? 'After food',
      instructions: map['instructions'] as String? ?? '',
      totalStock: (map['total_stock'] as num?)?.toInt() ?? 0,
      remainingStock: (map['remaining_stock'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (map['low_stock_threshold'] as num?)?.toInt() ?? 5,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: map['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      schedules: schedules ?? [],
    );
  }

  MedicineModel copyWith({
    int? id,
    int? userId,
    String? name,
    String? medicineType,
    String? dosage,
    String? frequency,
    String? startDate,
    String? endDate,
    String? foodTiming,
    String? instructions,
    int? totalStock,
    int? remainingStock,
    int? lowStockThreshold,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
    List<MedicineScheduleModel>? schedules,
  }) {
    return MedicineModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      medicineType: medicineType ?? this.medicineType,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      foodTiming: foodTiming ?? this.foodTiming,
      instructions: instructions ?? this.instructions,
      totalStock: totalStock ?? this.totalStock,
      remainingStock: remainingStock ?? this.remainingStock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      schedules: schedules ?? this.schedules,
    );
  }
}
