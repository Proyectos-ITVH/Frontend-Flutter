// Importa widgets básicos de Flutter
import 'package:flutter/material.dart';

// Importa Firebase Authentication para recuperación de contraseña
import 'package:firebase_auth/firebase_auth.dart';

// Pantalla de recuperación de contraseña
class RecPass extends StatefulWidget {
  const RecPass({super.key});

  @override
  State<RecPass> createState() => _RecPassState();
}

class _RecPassState extends State<RecPass> {
  // Controlador para el campo de correo electrónico
  final TextEditingController _emailController = TextEditingController();

  // Controla el estado de carga (spinner)
  bool _isLoading = false;

  // Método para enviar el correo de recuperación
  Future<void> _recoverPassword() async {
    // Obtiene el correo ingresado y elimina espacios
    String email = _emailController.text.trim();

    // Validación: correo vacío
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor ingrese su correo electrónico"),
        ),
      );
      return;
    }

    // Activa indicador de carga
    setState(() {
      _isLoading = true;
    });

    try {
      // Envía correo de recuperación usando Firebase Auth
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // Mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Correo de recuperación enviado. Verifique su bandeja.",
          ),
        ),
      );

      // Regresa a la pantalla anterior
      Navigator.pop(context);
    } catch (e) {
      // Manejo de errores
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    // Desactiva indicador de carga
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Color de fondo general
      backgroundColor: const Color.fromARGB(255, 255, 254, 255),

      // Barra superior
      appBar: AppBar(
        title: const Text("Recuperar Contraseña"),
        backgroundColor: Color(0xFF005BBB),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      // Contenido principal
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Card(
              // Bordes redondeados
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              // Color semitransparente de la tarjeta
              color: const Color.fromARGB(156, 59, 46, 127),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Texto informativo
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

                    // Campo de texto para el correo
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Correo electrónico",
                        prefixIcon: Icon(Icons.email, color: Color(0xFF005BBB)),
                        filled: true,
                        fillColor: Color(0xFF005BBB).withOpacity(0.1),
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF005BBB),
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                    ),

                    const SizedBox(height: 20),

                    // Muestra loader o botón según estado
                    _isLoading
                        ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                        : ElevatedButton(
                          onPressed: _recoverPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF005BBB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
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
