import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:bcrypt/bcrypt.dart'; // <-- Importar bcrypt
import 'recPass.dart';
import 'datos.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  /// ===============================
  /// GUARDAR TOKEN FCM
  /// ===============================
  Future<void> _saveFcmToken(String email) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      QueryDocumentSnapshot? userDoc;

      for (var doc in snapshot.docs) {
        String firestoreEmail = doc['email'];
        if (firestoreEmail.toLowerCase() == email.toLowerCase()) {
          userDoc = doc;
          break;
        }
      }

      if (userDoc == null) return;

      await FirebaseFirestore.instance.collection('users').doc(userDoc.id).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error guardando token: $e");
    }
  }

  /// ===============================
  /// LOGIN SOLO CON FIRESTORE + BCRYPT
  /// ===============================
  Future<void> _login() async {
    String user = _userController.text.trim();
    String pass = _passController.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor llena todos los campos")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot snapshot;

      // Buscar usuario por email o nombre
      if (user.contains("@")) {
        snapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: user)
                .limit(1)
                .get();
      } else {
        snapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .where('nombre', isEqualTo: user)
                .limit(1)
                .get();
      }

      if (snapshot.docs.isEmpty) {
        throw Exception("Usuario no encontrado");
      }

      var userDoc = snapshot.docs.first;
      var userData = userDoc.data() as Map<String, dynamic>;

      // ================================
      // VALIDAR CONTRASEÑA CON BCRYPT
      // ================================
      String hashedPassword = userData['password'];
      bool passwordMatches = BCrypt.checkpw(pass, hashedPassword);

      if (!passwordMatches) {
        throw Exception("Contraseña incorrecta");
      }

      // ================================
      // GUARDAR DATOS EN SHARED PREFERENCES
      // ================================
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', userData['email'] ?? '');
      await prefs.setString('user_uid', userDoc.id);
      await prefs.setString('user_nombre', userData['nombre'] ?? '');
      await prefs.setString(
        'user_numeroTelefonico',
        userData['numeroTelefonico'] ?? '',
      );
      await prefs.setString('user_rol', userData['rolUser'] ?? '');

      // ================================
      // GUARDAR TOKEN FCM
      // ================================
      if (userData['email'] != null) {
        await _saveFcmToken(userData['email']);
      }

      // ================================
      // NAVEGAR A PANTALLA PRINCIPAL
      // ================================
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DatosScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 254, 255),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
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
                  Image.asset("assets/logo.png", height: 100),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _userController,
                    label: "Email o Nombre",
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 15),
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
                        color: const Color(0xFF005BBB),
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF005BBB)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF005BBB).withOpacity(0.1),
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
