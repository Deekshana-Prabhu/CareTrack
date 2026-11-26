class UserModel {
  final int? id;
  final String name;
  final String email;
  final String? passwordHash;
  final int age;
  final String gender;
  final double height; // in cm
  final double weight; // in kg
  final String bloodGroup;
  final String medicalHistory;
  final String allergies;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String createdAt;
  final String updatedAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    this.passwordHash,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.bloodGroup,
    required this.medicalHistory,
    required this.allergies,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password_hash': passwordHash,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'blood_group': bloodGroup,
      'medical_history': medicalHistory,
      'allergies': allergies,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      passwordHash: map['password_hash'] as String?,
      age: (map['age'] as num?)?.toInt() ?? 0,
      gender: map['gender'] as String? ?? 'Other',
      height: (map['height'] as num?)?.toDouble() ?? 0.0,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      bloodGroup: map['blood_group'] as String? ?? '',
      medicalHistory: map['medical_history'] as String? ?? '',
      allergies: map['allergies'] as String? ?? '',
      emergencyContactName: map['emergency_contact_name'] as String? ?? '',
      emergencyContactPhone: map['emergency_contact_phone'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: map['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? passwordHash,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? bloodGroup,
    String? medicalHistory,
    String? allergies,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      allergies: allergies ?? this.allergies,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
