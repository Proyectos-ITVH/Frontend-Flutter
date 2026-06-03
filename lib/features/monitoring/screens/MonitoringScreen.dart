import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/monitoring_service.dart';
import '../utils/date_formatter.dart';
import '../utils/sensor_colors.dart';

// otras pantallas
import '../../calculations/screens/other_calcs_screen.dart';
import '../../export/screens/export_screen.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../../users/screens/user_list_screen.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  final MonitoringService _service = MonitoringService();

  String _estanqueSeleccionado = '';
  List<String> _listaEstanques = [];
  Map<String, bool> _sensoresAsignados = {};

  static const azul = Color(0xFF005BBB);
  static const dorado = Color(0xFFE3B23C);
  static const morado = Color(0xFF3C2E7F);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final estanques = await _service.cargarEstanques();

    setState(() {
      _listaEstanques = estanques;

      if (_estanqueSeleccionado.isEmpty && estanques.isNotEmpty) {
        _estanqueSeleccionado = estanques.first;
      }
    });

    await _loadSensors();
  }

  Future<void> _loadSensors() async {
    if (_estanqueSeleccionado.isEmpty) return;

    final sensores = await _service.cargarSensoresAsignados(
      _estanqueSeleccionado,
    );

    setState(() {
      _sensoresAsignados = sensores;
    });
  }

  Future<String> _getUserRol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_rol') ?? 'user';
  }

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
          // =========================
          // APPBAR (dat.dart exacto)
          // =========================
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
                    _listaEstanques
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (v) {
                  setState(() {
                    _estanqueSeleccionado = v!;
                  });
                  _loadSensors();
                },
              ),
            ),
            centerTitle: true,
          ),

          // =========================
          // BODY (FONDO BLANCO EXACTO)
          // =========================
          body: Container(
            color: Colors.white,
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.obtenerUltimaLectura(_estanqueSeleccionado),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No hay datos disponibles.",
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                final raw =
                    snapshot.data!.docs.first.data() as Map<String, dynamic>;

                final valores = raw['valores_sensores'] as Map<String, dynamic>;
                final timestamp = raw['timestamp'] as Timestamp;

                Map<String, String> sensoresFinal = {};

                _sensoresAsignados.forEach((key, active) {
                  if (active) sensoresFinal[key] = "Sin valores";
                });

                valores.forEach((k, v) {
                  sensoresFinal[k] = v.toString();
                });

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =========================
                      // CARD FECHA (dat.dart exacto)
                      // =========================
                      Card(
                        color: azul,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: const Text(
                            "Fecha y hora:",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            DateFormatter.formatTimestamp(timestamp),
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: const Icon(
                            Icons.access_time,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // =========================
                      // GRID (dat.dart exacto)
                      // =========================
                      Expanded(
                        child: GridView.builder(
                          itemCount: sensoresFinal.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.4,
                              ),
                          itemBuilder: (context, i) {
                            final key = sensoresFinal.keys.elementAt(i);
                            final value = sensoresFinal.values.elementAt(i);

                            final color =
                                value == "Sin valores"
                                    ? Colors.grey
                                    : SensorColors.determinarColor(key, value);

                            final valueWithUnit = SensorColors.agregarUnidad(
                              key,
                              value,
                            );

                            return Container(
                              decoration: BoxDecoration(
                                color: color,
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
                                      key,
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
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // =========================
          // BOTTOM NAV (SIN CAMBIOS)
          // =========================
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 0,
            type: BottomNavigationBarType.fixed,
            backgroundColor: morado,
            selectedItemColor: dorado,
            unselectedItemColor: Colors.white,
            onTap: (index) async {
              final snap = await _service.obtenerUltimaLecturaMap(
                _estanqueSeleccionado,
              );

              if (snap == null) return;

              final valores = Map<String, String>.from(
                snap['valores_sensores'].map(
                  (k, v) => MapEntry(k, v.toString()),
                ),
              );

              final actions = [
                () {},
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OtrosCalculosScreen(datos: valores),
                    ),
                  );
                },
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ExportScreen(
                            estanqueSeleccionado: _estanqueSeleccionado,
                          ),
                    ),
                  );
                },
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserPerfScreen()),
                  );
                },
              ];

              if (rol == "admin") {
                actions.add(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserListScreen()),
                  );
                });
              }

              if (index < actions.length) {
                actions[index]();
              }
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.description),
                label: "Informe",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.calculate),
                label: "Cálculos",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.upload),
                label: "Exportar",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "Perfil",
              ),
              if (rol == "admin")
                const BottomNavigationBarItem(
                  icon: Icon(Icons.admin_panel_settings),
                  label: "Usuarios",
                ),
            ],
          ),
        );
      },
    );
  }
}
