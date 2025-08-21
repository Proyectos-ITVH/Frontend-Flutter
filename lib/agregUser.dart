import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bcrypt/bcrypt.dart';

class AgregUserScreen extends StatefulWidget {
  const AgregUserScreen({super.key});

  @override
  State<AgregUserScreen> createState() => _AgregUserScreenState();
}

class _AgregUserScreenState extends State<AgregUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _rolController = TextEditingController();

  bool _loading = false;

  Future<void> _guardarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? creadorNombre = prefs.getString("user_nombre");

      final String nombre = _nombreController.text.trim();
      final String email = _emailController.text.trim();
      final String telefono = _telefonoController.text.trim();
      final String password = _passwordController.text.trim();
      final String rol =
          _rolController.text.trim().isNotEmpty
              ? _rolController.text.trim()
              : "user";

      // 🔒 Hashear la contraseña con bcrypt
      final String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      await FirebaseFirestore.instance.collection("users").add({
        "nombre": nombre,
        "email": email,
        "numeroTelefonico": telefono,
        "password": hashedPassword,
        "rolUser": rol,
        "createdBy": creadorNombre ?? "sistema",
        "createdAt": DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario agregado correctamente")),
      );

      Navigator.pop(context); // regresar después de guardar
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agregar Usuario"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black87, Colors.black54],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Card(
            color: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Center(
                      child: Text(
                        "Nuevo Usuario",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyanAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: "Nombre",
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                        labelStyle: TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? "Ingrese un nombre"
                                  : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Correo",
                        prefixIcon: const Icon(
                          Icons.email,
                          color: Colors.white,
                        ),
                        labelStyle: TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? "Ingrese un correo"
                                  : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _telefonoController,
                      decoration: InputDecoration(
                        labelText: "Teléfono",
                        prefixIcon: const Icon(
                          Icons.phone,
                          color: Colors.white,
                        ),
                        filled: true,
                        labelStyle: TextStyle(color: Colors.white),
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        prefixIcon: const Icon(Icons.lock, color: Colors.white),
                        filled: true,
                        labelStyle: TextStyle(color: Colors.white),
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      obscureText: true,
                      validator:
                          (value) =>
                              value != null && value.length < 6
                                  ? "Mínimo 6 caracteres"
                                  : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _rolController,
                      decoration: InputDecoration(
                        labelText: "Rol (ej: admin, user, etc.)",
                        prefixIcon: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                        ),
                        filled: true,
                        labelStyle: TextStyle(color: Colors.white),
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _loading ? null : _guardarUsuario,
                      child:
                          _loading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                "Guardar Usuario",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
