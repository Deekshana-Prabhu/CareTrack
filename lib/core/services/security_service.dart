import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecurityService {
  static const String _salt = 'CareTrack_Secure_Salt_2026';

  static String hashPassword(String password) {
    final bytes = utf8.encode(password + _salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }
}
