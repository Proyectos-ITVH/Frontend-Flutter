import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/user_service.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _rolController = TextEditingController();

  final UserService _userService = UserService();

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

      await _userService.createUser(
        nombre: nombre,
        email: email,
        telefono: telefono,
        password: password,
        rol: rol,
        creador: creadorNombre ?? "sistema",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Usuario creado correctamente")),
      );

      Navigator.pop(context);
    } on Exception catch (e) {
      String mensaje = "Error al crear usuario";

      if (e.toString().contains("email-already-in-use")) {
        mensaje = "❌ El correo ya está registrado";
      } else if (e.toString().contains("invalid-email")) {
        mensaje = "❌ Correo inválido";
      } else if (e.toString().contains("weak-password")) {
        mensaje = "❌ Contraseña muy débil";
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _rolController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 254, 255),

      appBar: AppBar(
        title: const Text("Agregar Usuario"),
        backgroundColor: const Color(0xFF005BBB),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: Container(
        padding: const EdgeInsets.all(16),

        child: Center(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: const Color.fromARGB(156, 59, 46, 127),
            elevation: 8,

            child: Padding(
              padding: const EdgeInsets.all(20),

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
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _nombreController,
                      label: "Nombre",
                      icon: Icons.person,
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? "Ingrese un nombre"
                                  : null,
                    ),

                    const SizedBox(height: 15),

                    _buildTextField(
                      controller: _emailController,
                      label: "Correo",
                      icon: Icons.email,
                      inputType: TextInputType.emailAddress,
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? "Ingrese un correo"
                                  : null,
                    ),

                    const SizedBox(height: 15),

                    _buildTextField(
                      controller: _telefonoController,
                      label: "Teléfono",
                      icon: Icons.phone,
                      inputType: TextInputType.phone,
                    ),

                    const SizedBox(height: 15),

                    _buildTextField(
                      controller: _passwordController,
                      label: "Contraseña",
                      icon: Icons.lock,
                      obscure: true,
                      validator:
                          (value) =>
                              value != null && value.length < 6
                                  ? "Mínimo 6 caracteres"
                                  : null,
                    ),

                    const SizedBox(height: 15),

                    _buildTextField(
                      controller: _rolController,
                      label: "Rol (admin, user, etc.)",
                      icon: Icons.admin_panel_settings,
                    ),

                    const SizedBox(height: 30),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005BBB),
                        foregroundColor: Colors.white,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: inputType,

      style: const TextStyle(color: Colors.white),

      decoration: InputDecoration(
        labelText: label,

        prefixIcon: Icon(icon, color: const Color(0xFF005BBB)),

        filled: true,

        fillColor: const Color(0xFF005BBB).withOpacity(0.1),

        labelStyle: const TextStyle(color: Colors.white70),

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),

      validator: validator,
    );
  }
}
