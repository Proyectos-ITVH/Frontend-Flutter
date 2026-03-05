import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'recPass.dart';
import 'datos.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores de texto para email/nombre y contraseña
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  // Variables de estado para loading y visibilidad de contraseña
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  /// Guarda el token FCM en Firestore en el documento del usuario (buscado por email)
  Future<void> _saveFcmToken(String email) async {
    final fcmToken =
        await FirebaseMessaging.instance.getToken(); // obtiene token FCM

    if (fcmToken != null) {
      // busca usuario por email
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final docId = snapshot.docs.first.id;

        // actualiza token FCM en el documento del usuario
        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          'fcmToken': fcmToken,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Future<void> _login() async {
    String user = _userController.text.trim(); // obtiene email/usuario
    String pass = _passController.text.trim(); // obtiene contraseña

    // Validación de campos vacíos
    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor llena todos los campos")),
      );
      return;
    }

    setState(() {
      _isLoading = true; // activa estado de carga
    });

    try {
      // Autenticación con Firebase Auth
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: user, password: pass);

      // Busca usuario en Firestore por email
      final QuerySnapshot userQuerySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: user)
              .get();

      // Si no existe por email, lo busca por nombre
      if (userQuerySnapshot.docs.isEmpty) {
        final snapshotByName =
            await FirebaseFirestore.instance
                .collection('users')
                .where('nombre', isEqualTo: user)
                .get();

        // Si tampoco existe por nombre → error
        if (snapshotByName.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Datos del usuario no encontrados")),
          );
        } else {
          // Si existe por nombre, obtiene los datos
          var userData = snapshotByName.docs.first.data();

          // Guarda datos en SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_email', userCredential.user?.email ?? '');
          await prefs.setString('user_uid', userCredential.user?.uid ?? '');
          await prefs.setString('user_nombre', userData['nombre'] ?? '');
          await prefs.setString(
            'user_numeroTelefonico',
            userData['numeroTelefonico'] ?? '',
          );
          await prefs.setString('user_rol', userData['rolUser'] ?? '');

          // Guarda token FCM
          if (userCredential.user?.email != null) {
            await _saveFcmToken(userCredential.user!.email!);
          }

          // Navega a pantalla de Datos
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DatosScreen()),
          );
        }
      } else {
        // Si existe por email, obtiene datos
        var userData =
            userQuerySnapshot.docs.first.data() as Map<String, dynamic>;

        // Guarda datos en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', userCredential.user?.email ?? '');
        await prefs.setString('user_uid', userCredential.user?.uid ?? '');
        await prefs.setString('user_nombre', userData['nombre'] ?? '');
        await prefs.setString(
          'user_numeroTelefonico',
          userData['numeroTelefonico'] ?? '',
        );
        await prefs.setString('user_rol', userData['rolUser'] ?? '');

        // Guarda token FCM
        if (userCredential.user?.email != null) {
          await _saveFcmToken(userCredential.user!.email!);
        }

        // Navega a Datos
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DatosScreen()),
        );
      }
    } catch (e) {
      // Manejo de errores de login
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }

    setState(() {
      _isLoading = false; // termina el loading
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo general de la pantalla
      backgroundColor: const Color.fromARGB(255, 255, 254, 255),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            // Tarjeta de login
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: const Color.fromARGB(156, 59, 46, 127),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Image.asset("assets/logo.png", height: 100),
                  const SizedBox(height: 20),

                  // Campo para email o nombre
                  _buildTextField(
                    controller: _userController,
                    label: "Email o Nombre",
                    icon: Icons.person,
                    inputType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 15),

                  // Campo de contraseña
                  _buildTextField(
                    controller: _passController,
                    label: "Contraseña",
                    icon: Icons.lock,
                    obscure: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Color(0xFF005BBB),
                      ),
                      // Cambia visibilidad de contraseña
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botón de iniciar sesión
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF005BBB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _login,
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              "Iniciar Sesión",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                  const SizedBox(height: 10),

                  // Botón para recuperar contraseña
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecPass(),
                        ),
                      );
                    },
                    child: const Text(
                      "¿Olvidó su contraseña? Recupérela aquí",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Constructor de campos de texto reutilizable
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: inputType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF005BBB)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Color(0xFF005BBB).withOpacity(0.1),
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
