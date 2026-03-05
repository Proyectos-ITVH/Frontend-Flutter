//  A la próxima persona que se encargue de trabajar con este código,
//  nomás te aviso que solo Dios y yo sabemos como va, pero si lo estas
//  modificando es porque yo ya no estoy, así que, que dios te bendiga,
//  porque solo el sabrá como jala esta cosa.
//    - The Black Fenix 937

// ===============================
// IMPORTACIONES
// ===============================

// Widgets base de Flutter (Material Design)
import 'package:flutter/material.dart';

// Firebase Firestore para leer datos en tiempo real
import 'package:cloud_firestore/cloud_firestore.dart';

// Para dar formato a fechas y horas
import 'package:intl/intl.dart';

// Para leer datos guardados localmente (rol del usuario)
import 'package:shared_preferences/shared_preferences.dart';

// Pantallas adicionales
import 'othercalcs.dart'; // Pantalla de otros cálculos
import 'export.dart'; // Pantalla para exportar datos
import 'userPerf.dart'; // Perfil del usuario
import 'crudUser.dart'; // CRUD de usuarios (solo admin)

// ===============================
// WIDGET PRINCIPAL
// ===============================
class DatosScreen extends StatefulWidget {
  const DatosScreen({super.key});

  @override
  State<DatosScreen> createState() => _DatosScreenState();
}

// ===============================
// ESTADO DEL WIDGET
// ===============================
class _DatosScreenState extends State<DatosScreen> {
  // Estanque actualmente seleccionado
  String _estanqueSeleccionado = 'Estanque1';

  // Colores base usados en la UI
  static const azul = Color(0xFF005BBB);
  static const dorado = Color(0xFFE3B23C);
  static const morado = Color(0xFF3C2E7F);

  // ===============================
  // OBTENER EL ROL DEL USUARIO
  // ===============================
  Future<String> _getUserRol() async {
    // Accede a las preferencias locales
    final prefs = await SharedPreferences.getInstance();

    // Retorna el rol guardado o "user" por defecto
    return prefs.getString('user_rol') ?? 'user';
  }

  // ===============================
  // FORMATEAR TIMESTAMP DE FIRESTORE
  // ===============================
  String _formatTimestamp(Timestamp timestamp) {
    // Convierte Timestamp a DateTime
    final DateTime dateTime = timestamp.toDate();

    // Define formato de fecha en español
    final DateFormat dateFormat = DateFormat(
      "d 'de' MMMM 'de' yyyy, h:mm:ss a",
      'es_ES',
    );

    // Retorna fecha formateada
    return dateFormat.format(dateTime);
  }

  // ===============================
  // DETERMINAR COLOR SEGÚN VALOR
  // ===============================
  Color determinarColor(String key, String valueStr) {
    // Convierte el valor a double
    double? value = double.tryParse(valueStr);
    if (value == null) return Colors.grey;

    // Reglas para TEMPERATURA
    if (key.toLowerCase().contains('temperatura')) {
      if (value < 27) return Colors.amber;
      if (value > 31) return Colors.red;
      return Colors.green;
    }

    // Reglas para PH
    if (key.toLowerCase().contains('ph')) {
      if (value < 6.5) return Colors.amber;
      if (value > 8.0) return Colors.red;
      return Colors.green;
    }

    // Reglas para OXÍGENO DISUELTO
    if (key.toLowerCase().contains('oxigeno')) {
      if (value < 5) return Colors.red;
      if (value >= 5 && value <= 8) return Colors.green;
      if (value > 8) return Colors.amber;
    }

    // Reglas para SÓLIDOS DISUELTOS / TDS / TURBIDEZ
    if (key.toLowerCase().contains('solidos_disueltos') ||
        key.toLowerCase().contains('tds') ||
        key.toLowerCase().contains('turbidez')) {
      if (value > 500) return Colors.red;
      if (value >= 0 && value <= 300) return Colors.green;
      return Colors.amber;
    }

    // Color por defecto
    return azul;
  }

  // ===============================
  // INTERFAZ PRINCIPAL
  // ===============================
  @override
  Widget build(BuildContext context) {
    // Espera obtener el rol del usuario
    return FutureBuilder<String>(
      future: _getUserRol(),
      builder: (context, snapshotRol) {
        // Mientras carga el rol
        if (!snapshotRol.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Rol obtenido
        final rol = snapshotRol.data!;

        return Scaffold(
          // ===============================
          // APP BAR
          // ===============================
          appBar: AppBar(
            backgroundColor: azul,
            foregroundColor: Colors.white,

            // Dropdown para seleccionar estanque
            title: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: azul,
                value: _estanqueSeleccionado,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Estanque1',
                    child: Text('Estanque 1'),
                  ),
                  DropdownMenuItem(
                    value: 'Estanque2',
                    child: Text('Estanque 2'),
                  ),
                ],
                onChanged: (String? newValue) {
                  // Cambia el estanque seleccionado
                  setState(() {
                    _estanqueSeleccionado = newValue!;
                  });
                },
              ),
            ),
            centerTitle: true,
          ),

          // ===============================
          // CUERPO PRINCIPAL
          // ===============================
          body: Container(
            color: Colors.white,
            child: StreamBuilder<QuerySnapshot>(
              // Consulta en tiempo real a Firestore
              stream:
                  FirebaseFirestore.instance
                      .collection('lecturas_sensores')
                      .where('estanqueId', isEqualTo: _estanqueSeleccionado)
                      .orderBy('timestamp', descending: true)
                      .limit(1)
                      .snapshots(),

              builder: (context, snapshot) {
                // Mientras carga
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error en Firestore
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                // Sin datos
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay datos disponibles.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                // ===============================
                // PROCESAR DATOS
                // ===============================
                final rawData =
                    snapshot.data!.docs.first.data() as Map<String, dynamic>;

                final valoresSensores =
                    rawData['valores_sensores'] as Map<String, dynamic>;

                final timestamp = rawData['timestamp'] as Timestamp;

                // Convierte valores a String
                final valoresSensoresString = valoresSensores.map((key, value) {
                  return MapEntry(key, value.toString());
                });

                // ===============================
                // UI DE DATOS
                // ===============================
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjeta de fecha y hora
                      Card(
                        color: azul,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: const Text(
                            'Fecha y hora:',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            _formatTimestamp(timestamp),
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: const Icon(
                            Icons.access_time,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Grid de sensores
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: valoresSensoresString.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.4,
                            ),
                        itemBuilder: (context, index) {
                          final sensorKey = valoresSensoresString.keys
                              .elementAt(index);
                          final sensorValue = valoresSensoresString.values
                              .elementAt(index);

                          final backgroundColor = determinarColor(
                            sensorKey,
                            sensorValue,
                          );

                          // Agrega unidad según tipo de sensor
                          String valueWithUnit = sensorValue;
                          if (sensorKey.toLowerCase().contains('temperatura')) {
                            valueWithUnit += ' °C';
                          } else if (sensorKey.toLowerCase().contains('ph')) {
                            valueWithUnit += ' pH';
                          } else if (sensorKey.toLowerCase().contains(
                            'oxigeno',
                          )) {
                            valueWithUnit += ' mg/l';
                          } else {
                            valueWithUnit += ' ppm';
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    valueWithUnit,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    sensorKey,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ===============================
          // BOTTOM NAVIGATION BAR
          // ===============================
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 0,
            type: BottomNavigationBarType.fixed,
            backgroundColor: morado,
            selectedItemColor: dorado,
            unselectedItemColor: Colors.white,
            iconSize: 28,

            // Acciones según el botón presionado
            onTap: (index) async {
              // Obtiene el último registro del estanque
              final snapshot =
                  await FirebaseFirestore.instance
                      .collection('lecturas_sensores')
                      .where('estanqueId', isEqualTo: _estanqueSeleccionado)
                      .orderBy('timestamp', descending: true)
                      .limit(1)
                      .get();

              final raw = snapshot.docs.first.data();
              final valoresSensores =
                  raw['valores_sensores'] as Map<String, dynamic>;

              final valoresSensoresString = valoresSensores.map((key, value) {
                return MapEntry(key, value.toString());
              });

              // Lista de acciones
              final List<VoidCallback> actions = [
                () {}, // Informe por estanque
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              OtrosCalculosScreen(datos: valoresSensoresString),
                    ),
                  );
                },
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              ExportarScreen(Estanque: _estanqueSeleccionado),
                    ),
                  );
                },
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserPerfScreen(),
                    ),
                  );
                },
              ];

              // Opción extra solo para admin
              if (rol == "admin") {
                actions.add(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CrudUserScreen(),
                    ),
                  );
                });
              }

              if (index < actions.length) {
                actions[index]();
              }
            },

            // Items visibles
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.description_rounded),
                label: 'Informe x estanque',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.calculate_rounded),
                label: 'Otros cálculos',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.file_upload_rounded),
                label: 'Exportar archivos',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Perfil',
              ),
              if (rol == "admin")
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_add_alt_1_rounded),
                  label: 'Usuarios CRUD',
                ),
            ],
          ),
        );
      },
    );
  }
}
