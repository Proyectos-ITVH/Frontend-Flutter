// ignore: file_names
// Importa widgets básicos de Flutter
import 'package:flutter/material.dart';

// Manejo de almacenamiento local (sesión del usuario)
import 'package:shared_preferences/shared_preferences.dart';

// Pantalla de login (para cerrar sesión)
import 'loginScreen.dart';

// Firestore para obtener y actualizar datos del usuario
import 'package:cloud_firestore/cloud_firestore.dart';

// Librería para cifrar y validar contraseñas
import 'package:bcrypt/bcrypt.dart';

// Pantalla de perfil de usuario
class UserPerfScreen extends StatefulWidget {
  const UserPerfScreen({super.key});

  @override
  State<UserPerfScreen> createState() => _UserPerfScreenState();
}

class _UserPerfScreenState extends State<UserPerfScreen> {
  // Datos del usuario
  String email = '';
  String nombre = '';
  String numero = '';

  // Colores usados en la interfaz
  static const Color azul = Color(0xFF005BBB);
  static const Color dorado = Color(0xFFE3B23C);

  @override
  void initState() {
    super.initState();
    // Carga los datos del usuario al iniciar la pantalla
    _loadUserData();
  }

  // Obtiene datos guardados localmente (SharedPreferences)
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString('user_email') ?? '';
      nombre = prefs.getString('user_nombre') ?? '';
      numero = prefs.getString('user_numeroTelefonico') ?? '';
    });
  }

  // Cierra sesión limpiando preferencias y regresando al login
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  // Muestra el diálogo para seleccionar qué datos modificar
  Future<void> _modificarPerfil() async {
    // Flags para saber qué campos cambiar
    bool cambiarNombre = false;
    bool cambiarEmail = false;
    bool cambiarNumero = false;
    bool cambiarPass = false;

    // Controladores de los campos
    final nombreCtrl = TextEditingController(text: nombre);
    final emailCtrl = TextEditingController(text: email);
    final numeroCtrl = TextEditingController(text: numero);
    final newPassCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setStateDialog) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: const Text(
                    'Modificar Perfil',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Cambiar nombre
                        CheckboxListTile(
                          title: const Text(
                            'Cambiar nombre',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: cambiarNombre,
                          onChanged:
                              (val) =>
                                  setStateDialog(() => cambiarNombre = val!),
                        ),
                        if (cambiarNombre)
                          TextField(
                            controller: nombreCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Nuevo nombre',
                              labelStyle: TextStyle(color: Colors.white70),
                            ),
                          ),

                        // Cambiar email
                        CheckboxListTile(
                          title: const Text(
                            'Cambiar email',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: cambiarEmail,
                          onChanged:
                              (val) =>
                                  setStateDialog(() => cambiarEmail = val!),
                        ),
                        if (cambiarEmail)
                          TextField(
                            controller: emailCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Nuevo email',
                              labelStyle: TextStyle(color: Colors.white70),
                            ),
                          ),

                        // Cambiar teléfono
                        CheckboxListTile(
                          title: const Text(
                            'Cambiar teléfono',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: cambiarNumero,
                          onChanged:
                              (val) =>
                                  setStateDialog(() => cambiarNumero = val!),
                        ),
                        if (cambiarNumero)
                          TextField(
                            controller: numeroCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Nuevo teléfono',
                              labelStyle: TextStyle(color: Colors.white70),
                            ),
                          ),

                        // Cambiar contraseña
                        CheckboxListTile(
                          title: const Text(
                            'Cambiar contraseña',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: cambiarPass,
                          onChanged:
                              (val) => setStateDialog(() => cambiarPass = val!),
                        ),
                        if (cambiarPass)
                          TextField(
                            controller: newPassCtrl,
                            style: const TextStyle(color: Colors.white),
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Nueva contraseña',
                              labelStyle: TextStyle(color: Colors.white70),
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    // Cancelar cambios
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Cancelar",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    // Pasar a confirmación
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: () {
                        // Validar que al menos un campo esté seleccionado
                        if (!cambiarNombre &&
                            !cambiarEmail &&
                            !cambiarNumero &&
                            !cambiarPass) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Seleccione al menos un campo para modificar",
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        _confirmarContrasena(
                          cambiarNombre,
                          cambiarEmail,
                          cambiarNumero,
                          cambiarPass,
                          nombreCtrl,
                          emailCtrl,
                          numeroCtrl,
                          newPassCtrl,
                        );
                      },
                      child: const Text("Siguiente"),
                    ),
                  ],
                ),
          ),
    );
  }

  // Confirma la contraseña antes de guardar cambios
  Future<void> _confirmarContrasena(
    bool cambiarNombre,
    bool cambiarEmail,
    bool cambiarNumero,
    bool cambiarPass,
    TextEditingController nombreCtrl,
    TextEditingController emailCtrl,
    TextEditingController numeroCtrl,
    TextEditingController newPassCtrl,
  ) async {
    final passCtrl = TextEditingController();
    final prefs = await SharedPreferences.getInstance();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              "Confirmar cambios",
              style: TextStyle(color: Colors.white),
            ),
            content: TextField(
              controller: passCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Ingrese su contraseña para guardar cambios",
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancelar",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () async {
                  String currentPass = passCtrl.text.trim();

                  // Validación de contraseña vacía
                  if (currentPass.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Debe ingresar su contraseña"),
                      ),
                    );
                    return;
                  }

                  // Obtiene usuario por email
                  final snapshot =
                      await FirebaseFirestore.instance
                          .collection("users")
                          .where("email", isEqualTo: email)
                          .get();

                  if (snapshot.docs.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Usuario no encontrado")),
                    );
                    return;
                  }

                  final doc = snapshot.docs.first;
                  final data = doc.data();
                  final hash = data["password"];

                  // Verifica contraseña usando BCrypt
                  if (!BCrypt.checkpw(currentPass, hash)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Contraseña incorrecta")),
                    );
                    return;
                  }

                  // Datos a actualizar
                  Map<String, dynamic> updateData = {};
                  if (cambiarNombre)
                    updateData["nombre"] = nombreCtrl.text.trim();
                  if (cambiarEmail) updateData["email"] = emailCtrl.text.trim();
                  if (cambiarNumero)
                    updateData["numeroTelefonico"] = numeroCtrl.text.trim();
                  if (cambiarPass)
                    updateData["password"] = BCrypt.hashpw(
                      newPassCtrl.text.trim(),
                      BCrypt.gensalt(),
                    );

                  // Actualiza Firestore
                  await FirebaseFirestore.instance
                      .collection("users")
                      .doc(doc.id)
                      .update(updateData);

                  // Actualiza datos locales
                  if (updateData.containsKey("nombre"))
                    await prefs.setString('user_nombre', updateData["nombre"]);
                  if (updateData.containsKey("email"))
                    await prefs.setString('user_email', updateData["email"]);
                  if (updateData.containsKey("numeroTelefonico"))
                    await prefs.setString(
                      'user_numeroTelefonico',
                      updateData["numeroTelefonico"],
                    );

                  // Actualiza UI
                  setState(() {
                    if (updateData.containsKey("nombre"))
                      nombre = updateData["nombre"];
                    if (updateData.containsKey("email"))
                      email = updateData["email"];
                    if (updateData.containsKey("numeroTelefonico"))
                      numero = updateData["numeroTelefonico"];
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Perfil actualizado correctamente"),
                    ),
                  );
                },
                child: const Text("Guardar"),
              ),
            ],
          ),
    );
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: const Color.fromARGB(156, 59, 46, 127),
            elevation: 12,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar del usuario
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

                  // Nombre
                  Text(
                    nombre.isNotEmpty ? nombre : 'Usuario',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  // Email
                  Text(
                    email.isNotEmpty ? email : 'Sin correo',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),

                  // Teléfono
                  Text(
                    numero.isNotEmpty ? "Tel: $numero" : 'Sin teléfono',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),

                  // Botón modificar perfil
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azul,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text("Modificar perfil"),
                    onPressed: _modificarPerfil,
                  ),

                  const SizedBox(height: 10),

                  // Botón cerrar sesión
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
