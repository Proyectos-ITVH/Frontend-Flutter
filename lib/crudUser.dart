// Importa los widgets básicos de Flutter (Material Design)
import 'package:flutter/material.dart';

// Importa Firestore para usar la base de datos en la nube
import 'package:cloud_firestore/cloud_firestore.dart';

// HTTP para conectar con Render
import 'dart:convert';
import 'package:http/http.dart' as http;

// Pantalla para agregar un usuario nuevo
import 'agregUser.dart';

// Widget principal del CRUD de usuarios
class CrudUserScreen extends StatefulWidget {
  const CrudUserScreen({super.key});

  @override
  State<CrudUserScreen> createState() => _CrudUserScreenState();
}

// Estado del widget (maneja lógica y datos)
class _CrudUserScreenState extends State<CrudUserScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = false;

  static const Color azul = Color(0xFF005BBB);
  static const Color morado = Color(0xFF3C2E7F);

  final String baseUrl = "https://firestore-listener-t3ge.onrender.com";

  // ===============================
  // 🗑️ ELIMINAR USUARIO (CONFIRM + RENDER)
  // ===============================
  Future<void> _eliminarUsuario(String uid, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: morado,
            title: const Text(
              'Confirmar eliminación',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              '¿Eliminar usuario $nombre?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Aceptar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/delete-user"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"uid": uid}),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuario eliminado correctamente")),
        );
      } else {
        throw Exception("Error en servidor");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _loading = false);
  }

  // ===============================
  // ✏️ EDITAR USUARIO (RENDER)
  // ===============================
  Future<void> _editarUsuario(String uid, Map<String, dynamic> userData) async {
    final nombreController = TextEditingController(text: userData['nombre']);
    final telefonoController = TextEditingController(
      text: userData['numeroTelefonico'],
    );
    final rolController = TextEditingController(text: userData['rolUser']);
    final emailController = TextEditingController(text: userData['email']);
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: morado,
            title: const Text(
              'Editar usuario',
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),

                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),

                  TextField(
                    controller: telefonoController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),

                  TextField(
                    controller: rolController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nueva contraseña (opcional)',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white),
                ),
              ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: azul),
                onPressed: () async {
                  try {
                    final res = await http.post(
                      Uri.parse("$baseUrl/update-user"),
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode({
                        "uid": uid,
                        "nombre": nombreController.text.trim(),
                        "telefono": telefonoController.text.trim(),
                        "rol": rolController.text.trim(),
                        "email": emailController.text.trim(),
                        "password":
                            passwordController.text.isNotEmpty
                                ? passwordController.text.trim()
                                : null,
                      }),
                    );

                    if (res.statusCode == 200) {
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Usuario actualizado")),
                      );
                    } else {
                      throw Exception("Error servidor");
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                },
                child: const Text(
                  'Guardar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text('CRUD Usuarios'),
        backgroundColor: azul,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(child: Text('No hay usuarios'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final userDoc = docs[index];
                      final data = userDoc.data() as Map<String, dynamic>;

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: morado,
                        margin: const EdgeInsets.symmetric(vertical: 8),

                        child: ListTile(
                          title: Text(
                            data['nombre'] ?? '',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            data['email'] ?? '',
                            style: const TextStyle(color: Colors.white70),
                          ),

                          trailing: SizedBox(
                            width: 130,
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                    ),
                                    onPressed:
                                        () => _editarUsuario(userDoc.id, data),
                                    child: const Icon(Icons.edit, size: 20),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed:
                                        () => _eliminarUsuario(
                                          userDoc.id,
                                          data['nombre'] ?? 'usuario',
                                        ),
                                    child: const Icon(Icons.delete, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AgregUserScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
