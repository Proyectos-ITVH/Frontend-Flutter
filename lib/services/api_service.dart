import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ⚠️ Cambia esta IP por la de tu servidor Flask
  static const String baseUrl = 'http://10.0.2.2:5000';

  static Future<List<dynamic>> getUsuarios() async {
    final response = await http.get(Uri.parse('$baseUrl/usuarios'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar los usuarios');
    }
  }

  static Future<void> crearUsuario(String nombre, String apellido) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre': nombre, 'apellido': apellido}),
    );
    if (response.statusCode != 201) {
      throw Exception('Error al crear usuario');
    }
  }
}
