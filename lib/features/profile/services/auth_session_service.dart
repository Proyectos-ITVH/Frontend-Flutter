import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/screens/login_screen.dart';

class AuthSessionService {
  static Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
