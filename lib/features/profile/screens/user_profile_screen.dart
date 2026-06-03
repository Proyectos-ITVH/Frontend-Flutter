import 'package:flutter/material.dart';
import '../services/user_profile_service.dart';
import '../services/auth_session_service.dart';

class UserPerfScreen extends StatefulWidget {
  const UserPerfScreen({super.key});

  @override
  State<UserPerfScreen> createState() => _UserPerfScreenState();
}

class _UserPerfScreenState extends State<UserPerfScreen> {
  String email = '';
  String nombre = '';
  String numero = '';
  String rol = '';

  bool isLoading = true;

  static const Color azul = Color(0xFF005BBB);
  static const Color dorado = Color(0xFFE3B23C);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await UserProfileService.getProfile();

      setState(() {
        email = data.email;
        nombre = data.nombre;
        numero = data.numeroTelefonico;
        rol = data.rol;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _logout() async {
    await AuthSessionService.logout(context);
  }

  Future<void> _modificarPerfil() async {
    final result = await UserProfileService.updateProfileDialog(
      context: context,
      nombreActual: nombre,
      emailActual: email,
      numeroActual: numero,
    );

    if (result == true) {
      _loadUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: azul,
        foregroundColor: Colors.white,
        title: const Text("Perfil de Usuario"),
        centerTitle: true,
      ),

      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: const Color.fromARGB(156, 59, 46, 127),
                    elevation: 12,

                    child: Padding(
                      padding: const EdgeInsets.all(20),

                      child: Column(
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: dorado,
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            nombre.isNotEmpty ? nombre : 'Usuario',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Text(email.isNotEmpty ? email : 'Sin correo'),

                          Text(
                            numero.isNotEmpty ? "Tel: $numero" : 'Sin teléfono',
                          ),

                          const SizedBox(height: 20),

                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: azul,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.edit),
                            label: const Text("Modificar perfil"),
                            onPressed: _modificarPerfil,
                          ),

                          const SizedBox(height: 10),

                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.logout),
                            label: const Text("Cerrar sesión"),
                            onPressed: _logout,
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
