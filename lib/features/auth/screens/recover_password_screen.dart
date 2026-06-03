import 'package:flutter/material.dart';
import '../services/recover_password_service.dart';

class RecPass extends StatefulWidget {
  const RecPass({super.key});

  @override
  State<RecPass> createState() => _RecPassState();
}

class _RecPassState extends State<RecPass> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _recoverPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor ingrese su correo electrónico"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await RecoverPasswordService.sendResetEmail(
      context: context,
      email: email,
    );

    setState(() => _isLoading = false);

    if (result) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 254, 255),
      appBar: AppBar(
        title: const Text("Recuperar Contraseña"),
        backgroundColor: const Color(0xFF005BBB),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: const Color.fromARGB(156, 59, 46, 127),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Ingrese su correo electrónico para enviar un enlace de recuperación.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Correo electrónico",
                        prefixIcon: const Icon(
                          Icons.email,
                          color: Color(0xFF005BBB),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF005BBB).withOpacity(0.1),
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color(0xFF005BBB),
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    _isLoading
                        ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                        : ElevatedButton(
                          onPressed: _recoverPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF005BBB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            "Enviar Correo",
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
