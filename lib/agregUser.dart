// Widgets básicos de Flutter
import 'package:flutter/material.dart';

// Firestore para guardar información del usuario
import 'package:cloud_firestore/cloud_firestore.dart';

// Firebase Authentication para crear usuarios
import 'package:firebase_auth/firebase_auth.dart';

// SharedPreferences para obtener datos locales (ej. quién crea el usuario)
import 'package:shared_preferences/shared_preferences.dart';

// BCrypt para encriptar contraseñas antes de guardarlas
import 'package:bcrypt/bcrypt.dart'; // 👈 para encriptar contraseñas

// Pantalla para agregar un nuevo usuario
class AgregUserScreen extends StatefulWidget {
  const AgregUserScreen({super.key});

  @override
  State<AgregUserScreen> createState() => _AgregUserScreenState();
}

class _AgregUserScreenState extends State<AgregUserScreen> {
  // Key para validar el formulario
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos del formulario
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _rolController = TextEditingController();

  // Variable para mostrar loader mientras se guarda
  bool _loading = false;

  // Método que guarda el usuario en Auth y Firestore
  Future<void> _guardarUsuario() async {
    // Valida el formulario
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // Obtener el nombre del usuario que está creando el nuevo usuario
      final prefs = await SharedPreferences.getInstance();
      final String? creadorNombre = prefs.getString("user_nombre");

      // Obtener valores del formulario
      final String nombre = _nombreController.text.trim();
      final String email = _emailController.text.trim();
      final String telefono = _telefonoController.text.trim();
      final String password = _passwordController.text.trim();

      // Si no se escribe rol, por defecto será "user"
      final String rol =
          _rolController.text.trim().isNotEmpty
              ? _rolController.text.trim()
              : "user";

      // 🔒 Encriptar la contraseña antes de guardarla en Firestore
      final String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      // Crear usuario en Firebase Authentication
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;

      // Si el usuario se creó correctamente
      if (user != null) {
        // Guardar información adicional en Firestore
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "nombre": nombre,
          "email": email,
          "numeroTelefonico": telefono,
          "password": hashedPassword, // 👈 contraseña encriptada
          "rolUser": rol,
          "createdBy": creadorNombre ?? "sistema",
          "createdAt": DateTime.now(),
        });

        // Mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuario agregado correctamente")),
        );

        // Regresa a la pantalla anterior
        Navigator.pop(context);
      }
    }
    // Manejo de errores específicos de Firebase Auth
    on FirebaseAuthException catch (e) {
      String mensaje = "Ocurrió un error.";

      if (e.code == 'email-already-in-use') {
        mensaje = "Este correo ya está registrado.";
      } else if (e.code == 'invalid-email') {
        mensaje = "El correo no es válido.";
      } else if (e.code == 'weak-password') {
        mensaje = "La contraseña es demasiado débil.";
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    }
    // Cualquier otro error
    catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 254, 255),

      // Barra superior
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
              padding: const EdgeInsets.all(20.0),

              // Formulario
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

                    // Campo Nombre
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

                    // Campo Correo
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

                    // Campo Teléfono
                    _buildTextField(
                      controller: _telefonoController,
                      label: "Teléfono",
                      icon: Icons.phone,
                      inputType: TextInputType.phone,
                    ),
                    const SizedBox(height: 15),

                    // Campo Contraseña
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

                    // Campo Rol
                    _buildTextField(
                      controller: _rolController,
                      label: "Rol (ej: admin, user, etc.)",
                      icon: Icons.admin_panel_settings,
                    ),
                    const SizedBox(height: 30),

                    // Botón Guardar
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

  // 🔹 Método reutilizable para construir TextFormField
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
