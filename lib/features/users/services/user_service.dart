import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/url.dart';

class UserService {
  Future<String?> getApiToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('apitoken');
  }

  Future<void> createUser({
    required String nombre,
    required String email,
    required String telefono,
    required String password,
    required String rol,
    required String creador,
  }) async {
    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

    final userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    final uid = userCredential.user!.uid;

    await FirebaseFirestore.instance.collection("users").doc(uid).set({
      "nombre": nombre,
      "email": email,
      "numeroTelefonico": telefono,
      "password": hashedPassword,
      "rolUser": rol,
      "createdBy": creador,
      "createdAt": DateTime.now(),
      "uid": uid,
    });
  }

  Future<String> deleteUser(String uid) async {
    final token = await getApiToken();

    final res = await http.delete(
      Uri.parse('${ApiConfig.API_BASE_URL}/users/$uid'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      return data['message'] ?? 'Usuario eliminado correctamente';
    }

    throw Exception(data['message'] ?? 'Error al eliminar usuario');
  }

  Future<String> updateUser({
    required String uid,
    required String nombre,
    required String telefono,
    required String rol,
    required String email,
    String? password,
  }) async {
    final token = await getApiToken();

    final Map<String, dynamic> body = {
      "nombre": nombre,
      "telefono": telefono,
      "rol": rol,
      "email": email,
    };

    if (password != null && password.isNotEmpty) {
      body["password"] = password;
    }

    final res = await http.put(
      Uri.parse('${ApiConfig.API_BASE_URL}/users/$uid'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      return data['message'] ?? 'Usuario actualizado';
    }

    throw Exception(data['message'] ?? 'Error al actualizar');
  }
}
