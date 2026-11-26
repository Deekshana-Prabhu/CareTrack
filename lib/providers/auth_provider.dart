import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';
import '../core/services/preference_service.dart';
import '../core/services/security_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  PreferenceService? _prefService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<void> initialize() async {
    _prefService = await PreferenceService.getInstance();
    final savedUserId = _prefService?.getCurrentUserId();
    if (savedUserId != null) {
      _currentUser = await _dbHelper.getUserById(savedUserId);
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required int age,
    required String gender,
    required double height,
    required double weight,
    required String bloodGroup,
    String medicalHistory = '',
    String allergies = '',
    String emergencyContactName = '',
    String emergencyContactPhone = '',
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Check if email already registered
      final existing = await _dbHelper.getUserByEmail(email);
      if (existing != null) {
        _errorMessage = 'An account with this email already exists';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final now = DateTime.now().toIso8601String();
      final hashedPassword = SecurityService.hashPassword(password);

      final newUser = UserModel(
        name: name.trim(),
        email: email.trim().toLowerCase(),
        passwordHash: hashedPassword,
        age: age,
        gender: gender,
        height: height,
        weight: weight,
        bloodGroup: bloodGroup,
        medicalHistory: medicalHistory.trim(),
        allergies: allergies.trim(),
        emergencyContactName: emergencyContactName.trim(),
        emergencyContactPhone: emergencyContactPhone.trim(),
        createdAt: now,
        updatedAt: now,
      );

      final id = await _dbHelper.insertUser(newUser);
      _currentUser = newUser.copyWith(id: id);
      await _prefService?.setCurrentUserId(id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Registration failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = await _dbHelper.getUserByEmail(email.trim().toLowerCase());
      if (user == null || user.passwordHash == null) {
        _errorMessage = 'Invalid email or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final isMatch = SecurityService.verifyPassword(password, user.passwordHash!);
      if (!isMatch) {
        _errorMessage = 'Invalid email or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = user;
      await _prefService?.setCurrentUserId(user.id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Login failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(UserModel updatedUser) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _dbHelper.updateUser(updatedUser);
      _currentUser = updatedUser;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Profile update failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await _prefService?.clearSession();
    notifyListeners();
  }
}
