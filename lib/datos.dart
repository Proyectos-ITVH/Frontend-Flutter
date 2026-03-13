// ===============================
// IMPORTACIONES
// ===============================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'othercalcs.dart';
import 'export.dart';
import 'userPerf.dart';
import 'crudUser.dart';

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
  String _estanqueSeleccionado = '';
  List<String> _listaEstanques = [];
  Map<String, bool> _sensoresAsignados = {};

  static const azul = Color(0xFF005BBB);
  static const dorado = Color(0xFFE3B23C);
  static const morado = Color(0xFF3C2E7F);

  // ===============================
  // INIT
  // ===============================
  @override
  void initState() {
    super.initState();
    _cargarEstanques();
  }

  // ===============================
  // CARGAR ESTANQUES
  // ===============================
  Future<void> _cargarEstanques() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('estanques').get();

    final estanques = snapshot.docs.map((doc) => doc.id).toList();

    setState(() {
      _listaEstanques = estanques;

      if (_estanqueSeleccionado.isEmpty && estanques.isNotEmpty) {
        _estanqueSeleccionado = estanques.first;
        _cargarSensoresAsignados();
      }
    });
  }

  // ===============================
  // CARGAR SENSORES DEL ESTANQUE
  // ===============================
  Future<void> _cargarSensoresAsignados() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('estanques')
            .doc(_estanqueSeleccionado)
            .get();

    if (doc.exists) {
      final data = doc.data();

      setState(() {
        _sensoresAsignados = Map<String, bool>.from(
          data?['sensores_asignados'] ?? {},
        );
      });
    }
  }

  // ===============================
  // OBTENER ROL
  // ===============================
  Future<String> _getUserRol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_rol') ?? 'user';
  }

  // ===============================
  // FORMATEAR FECHA
  // ===============================
  String _formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();

    final DateFormat dateFormat = DateFormat(
      "d 'de' MMMM 'de' yyyy, h:mm:ss a",
      'es_ES',
    );

    return dateFormat.format(dateTime);
  }

  // ===============================
  // COLOR SEGUN SENSOR
  // ===============================
  Color determinarColor(String key, String valueStr) {
    double? value = double.tryParse(valueStr);
    if (value == null) return Colors.grey;

    if (key.toLowerCase().contains('temperatura')) {
      if (value < 27) return Colors.amber;
      if (value > 31) return Colors.red;
      return Colors.green;
    }

    if (key.toLowerCase().contains('ph')) {
      if (value < 6.5) return Colors.amber;
      if (value > 8.0) return Colors.red;
      return Colors.green;
    }

    if (key.toLowerCase().contains('oxigeno')) {
      if (value < 5) return Colors.red;
      if (value >= 5 && value <= 8) return Colors.green;
      if (value > 8) return Colors.amber;
    }

    if (key.toLowerCase().contains('solidos_disueltos') ||
        key.toLowerCase().contains('tds') ||
        key.toLowerCase().contains('turbidez')) {
      if (value > 500) return Colors.red;
      if (value >= 0 && value <= 300) return Colors.green;
      return Colors.amber;
    }

    return azul;
  }

  // ===============================
  // INTERFAZ
  // ===============================
  @override
  Widget build(BuildContext context) {
    if (_listaEstanques.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FutureBuilder<String>(
      future: _getUserRol(),
      builder: (context, snapshotRol) {
        if (!snapshotRol.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final rol = snapshotRol.data!;

        return Scaffold(
          // ===============================
          // APP BAR
          // ===============================
          appBar: AppBar(
            backgroundColor: azul,
            foregroundColor: Colors.white,
            title: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: azul,
                value:
                    _listaEstanques.contains(_estanqueSeleccionado)
                        ? _estanqueSeleccionado
                        : null,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                items:
                    _listaEstanques.map((estanque) {
                      return DropdownMenuItem(
                        value: estanque,
                        child: Text(estanque),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _estanqueSeleccionado = newValue!;
                  });
                  _cargarSensoresAsignados();
                },
              ),
            ),
            centerTitle: true,
          ),

          // ===============================
          // BODY
          // ===============================
          body: Container(
            color: Colors.white,
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('lecturas_sensores')
                      .where('estanqueId', isEqualTo: _estanqueSeleccionado)
                      .orderBy('timestamp', descending: true)
                      .limit(1)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay datos disponibles.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                final rawData =
                    snapshot.data!.docs.first.data() as Map<String, dynamic>;

                final valoresSensores =
                    rawData['valores_sensores'] as Map<String, dynamic>;

                final timestamp = rawData['timestamp'] as Timestamp;

                // Crear mapa base usando sensores asignados
                Map<String, String> sensoresFinal = {};

                _sensoresAsignados.forEach((key, activo) {
                  if (activo) {
                    sensoresFinal[key] = "Sin valores";
                  }
                });

                // Sobrescribir con datos reales
                valoresSensores.forEach((key, value) {
                  sensoresFinal[key] = value.toString();
                });

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sensoresFinal.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.4,
                            ),
                        itemBuilder: (context, index) {
                          final sensorKey = sensoresFinal.keys.elementAt(index);
                          final sensorValue = sensoresFinal.values.elementAt(
                            index,
                          );

                          final backgroundColor =
                              sensorValue == "Sin valores"
                                  ? Colors.grey
                                  : determinarColor(sensorKey, sensorValue);

                          String valueWithUnit = sensorValue;

                          if (sensorValue != "Sin valores") {
                            if (sensorKey.toLowerCase().contains(
                              'temperatura',
                            )) {
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
          // BOTTOM NAV
          // ===============================
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 0,
            type: BottomNavigationBarType.fixed,
            backgroundColor: morado,
            selectedItemColor: dorado,
            unselectedItemColor: Colors.white,
            iconSize: 28,
            onTap: (index) async {
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

              final List<VoidCallback> actions = [
                () {},
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
