import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'selecStanq.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

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
      // Buscar usuario por email o nombre
      final snapshot =
          await FirebaseFirestore.instance
              .collection("users")
              .where("email", isEqualTo: user)
              .get();

      final snapshotName =
          await FirebaseFirestore.instance
              .collection("users")
              .where("nombre", isEqualTo: user)
              .get();

      final docs = snapshot.docs.isNotEmpty ? snapshot.docs : snapshotName.docs;

      if (docs.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Usuario no encontrado")));
      } else {
        final data = docs.first.data();
        String hash = data["password"];

        // Verificar con bcrypt
        if (BCrypt.checkpw(pass, hash)) {
          // Guardar datos en SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_email', data['email'] ?? '');
          await prefs.setString('user_nombre', data['nombre'] ?? '');
          await prefs.setString('user_numero', data['numeroTelefonico'] ?? '');
          await prefs.setString(
            'user_rol',
            data['rolUser'] ?? '',
          ); // Guardar rol

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SelecStanq()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Contraseña incorrecta")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            color: Colors.white.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset("assets/logo.png", height: 100),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _userController,
                    decoration: const InputDecoration(
                      labelText: "Email o Nombre",
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passController,
                    decoration: const InputDecoration(
                      labelText: "Contraseña",
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _login,
                        child: const Text("Iniciar Sesión"),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
