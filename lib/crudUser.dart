// Importa los widgets básicos de Flutter (Material Design)
import 'package:flutter/material.dart';

// Importa Firestore para usar la base de datos en la nube
import 'package:cloud_firestore/cloud_firestore.dart';

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
  // Instancia de Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Variable para mostrar un loader cuando se realiza una acción
  bool _loading = false;

  // Colores personalizados usados en la interfaz
  static const Color azul = Color(0xFF005BBB);
  static const Color morado = Color(0xFF3C2E7F);

  // ===============================
  // MÉTODO PARA ELIMINAR USUARIO
  // ===============================
  Future<void> _eliminarUsuario(String uid) async {
    // Activa el indicador de carga
    setState(() => _loading = true);
    try {
      // Elimina el documento del usuario por su ID
      await _firestore.collection("users").doc(uid).delete();

      // Muestra mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario eliminado de Firestore.")),
      );
    } catch (e) {
      // Muestra mensaje de error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al eliminar: $e")));
    }
    // Desactiva el indicador de carga
    setState(() => _loading = false);
  }

  // ===============================
  // MÉTODO PARA EDITAR USUARIO
  // ===============================
  Future<void> _editarUsuario(String uid, Map<String, dynamic> userData) async {
    // Controladores para los campos del formulario
    final nombreController = TextEditingController(text: userData['nombre']);
    final telefonoController = TextEditingController(
      text: userData['numeroTelefonico'],
    );
    final rolController = TextEditingController(text: userData['rolUser']);

    // Muestra un cuadro de diálogo para editar los datos
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: morado,
            title: const Text(
              'Editar usuario',
              style: TextStyle(color: Colors.white),
            ),

            // Contenido del formulario
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Campo nombre
                TextField(
                  controller: nombreController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),

                // Campo teléfono
                TextField(
                  controller: telefonoController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),

                // Campo rol
                TextField(
                  controller: rolController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),

            // Botones del diálogo
            actions: [
              // Botón cancelar
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white),
                ),
              ),

              // Botón guardar cambios
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: azul),
                onPressed: () async {
                  try {
                    // Actualiza los datos del usuario en Firestore
                    await _firestore.collection("users").doc(uid).update({
                      'nombre': nombreController.text.trim(),
                      'numeroTelefonico': telefonoController.text.trim(),
                      'rolUser': rolController.text.trim(),
                    });

                    // Cierra el diálogo
                    Navigator.pop(context);

                    // Mensaje de éxito
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Usuario actualizado')),
                    );
                  } catch (e) {
                    // Mensaje de error
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al actualizar: $e')),
                    );
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  // ===============================
  // INTERFAZ PRINCIPAL
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // Barra superior
      appBar: AppBar(
        title: const Text('CRUD Usuarios'),
        backgroundColor: azul,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      // Cuerpo de la pantalla
      body:
          _loading
              // Muestra loader si hay una operación en curso
              ? const Center(child: CircularProgressIndicator())
              // Escucha cambios en tiempo real de Firestore
              : StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  // Error al cargar datos
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  // Mientras carga la información
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Lista de documentos
                  final docs = snapshot.data!.docs;

                  // Si no hay usuarios
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay usuarios',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  // Lista de usuarios
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final userDoc = docs[index];
                      final userData = userDoc.data()! as Map<String, dynamic>;

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: morado,
                        margin: const EdgeInsets.symmetric(vertical: 8),

                        // Información del usuario
                        child: ListTile(
                          title: Text(
                            userData['nombre'] ?? 'Sin nombre',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            userData['email'] ?? 'Sin email',
                            style: const TextStyle(color: Colors.white70),
                          ),

                          // Botones editar y eliminar
                          trailing: SizedBox(
                            width: 130,
                            child: Row(
                              children: [
                                // Botón editar
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    onPressed:
                                        () => _editarUsuario(
                                          userDoc.id,
                                          userData,
                                        ),
                                    child: const Icon(Icons.edit, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Botón eliminar
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () async {
                                      // Confirmación antes de eliminar
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              backgroundColor: morado,
                                              title: const Text(
                                                'Confirmar eliminación',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              content: Text(
                                                '¿Eliminar usuario ${userData['nombre']}?',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text(
                                                    'Cancelar',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text(
                                                    'Eliminar',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                      );

                                      if (confirm == true) {
                                        await _eliminarUsuario(userDoc.id);
                                      }
                                    },
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

      // Botón flotante para agregar usuarios
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
