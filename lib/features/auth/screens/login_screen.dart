import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../../monitoring/screens/MonitoringScreen.dart';
import 'recover_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();

  final TextEditingController _email = TextEditingController();
  final TextEditingController _pass = TextEditingController();

  bool _loading = false;
  bool _showPass = false;

  Future<void> _login() async {
    final email = _email.text.trim();
    final pass = _pass.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Llena todos los campos")));
      return;
    }

    setState(() => _loading = true);

    try {
      final data = await _auth.login(email: email, password: pass);

      final token = data['token'];
      final user = data['user'];

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('apitoken', token);
      await prefs.setString('user_email', user['email'] ?? '');
      await prefs.setString('user_uid', user['uid'] ?? '');
      await prefs.setString('user_nombre', user['nombre'] ?? '');
      await prefs.setString(
        'user_numeroTelefonico',
        user['numeroTelefonico'] ?? '',
      );
      await prefs.setString('user_rol', user['rolUser'] ?? '');

      if (user['email'] != null) {
        await _auth.saveFcmToken(user['email']);
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MonitoringScreen()),
      );
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
      backgroundColor: const Color.fromARGB(255, 255, 254, 255),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: const Color.fromARGB(156, 59, 46, 127),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset("assets/logo.png", height: 100),

                  const SizedBox(height: 20),

                  _buildTextField(
                    controller: _email,
                    label: "Correo Electrónico",
                    icon: Icons.person,
                  ),

                  const SizedBox(height: 15),

                  _buildTextField(
                    controller: _pass,
                    label: "Contraseña",
                    icon: Icons.lock,
                    obscure: !_showPass,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPass ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF005BBB),
                      ),
                      onPressed: () {
                        setState(() {
                          _showPass = !_showPass;
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
                    onPressed: _loading ? null : _login,
                    child:
                        _loading
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
                        MaterialPageRoute(builder: (_) => const RecPass()),
                      );
                    },
                    child: const Text(
                      "¿Olvidó su contraseña? Recupérela aquí",
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
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
