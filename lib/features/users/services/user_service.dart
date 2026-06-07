import 'dart:convert';

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
  }) async {
    final token = await getApiToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.API_BASE_URL}/users/register'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "nombre": nombre,
        "email": email,
        "password": password,
        "numeroTelefonico": telefono,
        "rolUser": rol,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Error al registrar usuario');
    }
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
