import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/url.dart';

class UserProfileData {
  final String email;
  final String nombre;
  final String numeroTelefonico;
  final String rol;

  UserProfileData({
    required this.email,
    required this.nombre,
    required this.numeroTelefonico,
    required this.rol,
  });
}

class UserProfileService {
  static Future<UserProfileData> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('apitoken');

    if (token == null || token.isEmpty) {
      throw Exception("Token no encontrado");
    }

    final response = await http.get(
      Uri.parse("${ApiConfig.API_BASE_URL}/users/profile"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data["message"] ?? "Error obteniendo perfil");
    }

    return UserProfileData(
      email: data["email"] ?? '',
      nombre: data["nombre"] ?? '',
      numeroTelefonico: data["numeroTelefonico"] ?? '',
      rol: data["rolUser"] ?? '',
    );
  }

  static Future<bool?> updateProfileDialog({
    required BuildContext context,
    required String nombreActual,
    required String emailActual,
    required String numeroActual,
  }) async {
    bool cambiarNombre = false;
    bool cambiarEmail = false;
    bool cambiarNumero = false;
    bool cambiarPass = false;

    final nombreCtrl = TextEditingController(text: nombreActual);
    final emailCtrl = TextEditingController(text: emailActual);
    final numeroCtrl = TextEditingController(text: numeroActual);
    final passCtrl = TextEditingController();

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                "Modificar Perfil",
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    _check(
                      "Cambiar nombre",
                      cambiarNombre,
                      (v) => setStateDialog(() => cambiarNombre = v),
                      nombreCtrl,
                      "Nuevo nombre",
                    ),

                    _check(
                      "Cambiar email",
                      cambiarEmail,
                      (v) => setStateDialog(() => cambiarEmail = v),
                      emailCtrl,
                      "Nuevo email",
                    ),

                    _check(
                      "Cambiar teléfono",
                      cambiarNumero,
                      (v) => setStateDialog(() => cambiarNumero = v),
                      numeroCtrl,
                      "Nuevo teléfono",
                    ),

                    _check(
                      "Cambiar contraseña",
                      cambiarPass,
                      (v) => setStateDialog(() => cambiarPass = v),
                      passCtrl,
                      "Nueva contraseña",
                      obscure: true,
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancelar"),
                ),

                ElevatedButton(
                  onPressed: () async {
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      final token = prefs.getString('apitoken');

                      if (token == null || token.isEmpty) {
                        throw Exception("Token no encontrado");
                      }

                      final updateData = <String, dynamic>{};

                      if (cambiarNombre && nombreCtrl.text.isNotEmpty) {
                        updateData["nombre"] = nombreCtrl.text.trim();
                      }
                      if (cambiarEmail && emailCtrl.text.isNotEmpty) {
                        updateData["email"] = emailCtrl.text.trim();
                      }
                      if (cambiarNumero && numeroCtrl.text.isNotEmpty) {
                        updateData["numeroTelefonico"] = numeroCtrl.text.trim();
                      }
                      if (cambiarPass && passCtrl.text.isNotEmpty) {
                        updateData["password"] = passCtrl.text.trim();
                      }

                      final response = await http.put(
                        Uri.parse("${ApiConfig.API_BASE_URL}/users/profile"),
                        headers: {
                          "Content-Type": "application/json",
                          "Authorization": "Bearer $token",
                        },
                        body: jsonEncode(updateData),
                      );

                      final data = jsonDecode(response.body);

                      if (response.statusCode != 200) {
                        throw Exception(data["message"]);
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Perfil actualizado")),
                        );
                      }

                      Navigator.pop(context, true);
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  },
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _check(
    String title,
    bool value,
    Function(bool) onChanged,
    TextEditingController controller,
    String label, {
    bool obscure = false,
  }) {
    return Column(
      children: [
        CheckboxListTile(
          title: Text(title, style: const TextStyle(color: Colors.white)),
          value: value,
          onChanged: (v) => onChanged(v ?? false),
        ),
        if (value)
          TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Colors.white70),
            ),
          ),
      ],
    );
  }
}
