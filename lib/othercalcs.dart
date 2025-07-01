import 'package:flutter/material.dart';

class OtrosCalculosScreen extends StatelessWidget {
  final Map<String, String> datos;

  const OtrosCalculosScreen({super.key, required this.datos});

  @override
  Widget build(BuildContext context) {
    // Asegúrate de que los datos no sean nulos antes de usar el operador '!'
    final oxigeno =
        datos["Oxígeno disuelto"] != null
            ? double.parse(datos["Oxígeno disuelto"]!.split(" ").first)
            : 0.0;
    final ph = datos["pH"] != null ? double.parse(datos["pH"]!) : 7.0;
    final solidos =
        datos["Sólidos disueltos"] != null
            ? double.parse(datos["Sólidos disueltos"]!.split(" ").first)
            : 0.0;
    final temperatura =
        datos["Temperatura"] != null
            ? double.parse(datos["Temperatura"]!.split("°").first)
            : 20.0;

    // Asegúrate de que el amonio no sea nulo antes de parsearlo
    final amonio =
        datos["Amonio"] != null
            ? double.parse(datos["Amonio"]!.split(" ").first)
            : 10.2;

    // Cálculo de calidad del agua
    final double calidad =
        (100 - solidos) * 0.25 +
        (ph / 14 * 100) * 0.25 +
        (oxigeno / 10 * 100) * 0.25 +
        (100 - (temperatura - 20).abs() * 2) * 0.25;

    final String pureza = (100 - solidos).clamp(0, 100).toStringAsFixed(1);
    final String nivelPH =
        ph < 6.5
            ? "Ácido"
            : ph > 7.5
            ? "Básico"
            : "Neutro";

    // Nivel de Amonio mostrado de forma directa
    final String nivelAmonio = "${amonio.toStringAsFixed(2)} mg/L";

    final Map<String, String> calculos = {
      "Índice de calidad": "${calidad.toStringAsFixed(1)}%",
      "Pureza estimada": "$pureza%",
      "Nivel de pH": nivelPH,
      "Nivel de Amonio": nivelAmonio,
    };

    final keys = calculos.keys.toList();
    final values = calculos.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Otros cálculos"),
        backgroundColor: Colors.black,
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
                      style: TextStyle(color: Colors.grey[300], fontSize: 15),
                      textAlign: TextAlign.center,
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
