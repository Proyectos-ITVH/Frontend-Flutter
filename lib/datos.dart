import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'othercalcs.dart';
import 'export.dart';
import 'userPerf.dart';
import 'agregUser.dart';

class DatosScreen extends StatelessWidget {
  final String Estanque;

  const DatosScreen({super.key, required this.Estanque});

  Future<String> _getUserRol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_rol') ?? 'user';
  }

  @override
  Widget build(BuildContext context) {
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
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(Estanque),
            centerTitle: true,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('lecturas_sensores')
                    .where('estanqueId', isEqualTo: Estanque)
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
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              final rawData =
                  snapshot.data!.docs.first.data() as Map<String, dynamic>;
              final valoresSensores =
                  rawData['valores_sensores'] as Map<String, dynamic>;
              final valoresSensoresString = valoresSensores.map((key, value) {
                return MapEntry(key, value.toString());
              });

              return Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  itemCount: valoresSensoresString.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemBuilder: (context, index) {
                    final sensorKey = valoresSensoresString.keys.elementAt(
                      index,
                    );
                    final sensorValue = valoresSensoresString.values.elementAt(
                      index,
                    );

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              sensorValue,
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              sensorKey,
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 15,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 0,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.black,
            selectedItemColor: Colors.cyanAccent,
            unselectedItemColor: Colors.white,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
            ),
            iconSize: 28,
            onTap: (index) async {
              final snapshot =
                  await FirebaseFirestore.instance
                      .collection('lecturas_sensores')
                      .where('estanqueId', isEqualTo: Estanque)
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
                () {
                  // Informe x estanque
                },
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
                      builder: (context) => ExportarScreen(estanqueId: ''),
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
                      builder: (context) => const AgregUserScreen(),
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
                  label: 'Agregar usuario',
                ),
            ],
          ),
        );
      },
    );
  }
}
