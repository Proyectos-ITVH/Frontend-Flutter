import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'othercalcs.dart';
import 'export.dart';

class DatosScreen extends StatelessWidget {
  final String estanque;

  const DatosScreen({super.key, required this.estanque});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(estanque),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('temperatura')
                .doc('ultimo valor')
                .snapshots(), // ESCUCHA EN TIEMPO REAL
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'No hay datos disponibles.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final rawData = snapshot.data!.data() as Map<String, dynamic>;
          final datos = rawData.map((k, v) => MapEntry(k, v.toString()));
          final keys = datos.keys.toList();
          final values = datos.values.toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              itemCount: datos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemBuilder: (context, index) {
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
                          values[index],
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          keys[index],
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
        selectedItemColor: Colors.cyan,
        unselectedItemColor: Colors.white,
        backgroundColor: Colors.black,
        onTap: (index) async {
          final snapshot =
              await FirebaseFirestore.instance
                  .collection('temperatura')
                  .doc('ultimo valor')
                  .get();
          final raw = snapshot.data() ?? {};
          final datos = raw.map((k, v) => MapEntry(k, v.toString()));

          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtrosCalculosScreen(datos: datos),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExportarScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Informe x estanque',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Otros cálculos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.file_upload),
            label: 'Exportar archivos',
          ),
        ],
      ),
    );
  }
}
