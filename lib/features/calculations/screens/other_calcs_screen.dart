import 'package:flutter/material.dart';
import '../services/other_calcs_service.dart';

class OtrosCalculosScreen extends StatelessWidget {
  final Map<String, String> datos;

  static const azul = Color(0xFF005BBB);

  const OtrosCalculosScreen({super.key, required this.datos});

  @override
  Widget build(BuildContext context) {
    final result = OtherCalcsService.calcular(datos);

    final calculos = result.calculos;
    final keys = calculos.keys.toList();
    final values = calculos.values.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Otros cálculos"),
        backgroundColor: azul,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: calculos.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemBuilder: (context, index) {
            final key = keys[index];
            final value = values[index];

            final color = result.colores[key] ?? Colors.blue;

            return Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
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
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      key,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
