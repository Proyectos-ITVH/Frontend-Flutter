import 'package:flutter/material.dart';

class OtrosCalculosScreen extends StatelessWidget {
  final Map<String, String> datos;

  static const azul = Color(0xFF005BBB);
  static const dorado = Color(0xFFE3B23C);
  static const morado = Color(0xFF3C2E7F);

  const OtrosCalculosScreen({super.key, required this.datos});

  @override
  Widget build(BuildContext context) {
    final oxigeno = _parse(datos["oxigeno"]);
    final ph = _parse(datos["ph"]);
    final solidos = _parse(datos["solidos_disueltos"]);
    final temperatura = _parse(datos["temperatura"]);
    final turbidez = _parse(datos["turbidez"]);

    // ⚠️ Cálculo del amonio estimado
    final amonio = calcularAmonioEstimado(
      ph: ph,
      temperatura: temperatura,
      oxigeno: oxigeno,
      solidos: solidos,
      turbidez: turbidez,
    );

    final double oxigenoScore =
        oxigeno < 5
            ? 0
            : oxigeno > 8
            ? 100
            : ((oxigeno - 5) / 3) * 100;
    final double phScore =
        ph < 6.5
            ? 0
            : ph > 7.5
            ? 100
            : ((ph - 6.5) / 1) * 100;
    final double temperaturaScore =
        temperatura < 20
            ? 0
            : temperatura > 25
            ? 100
            : ((25 - temperatura) / 5) * 100;
    final double solidosScore = solidos > 200 ? 0 : (1 - (solidos / 200)) * 100;
    final double amonioScore = amonio > 0.02 ? 0 : (1 - (amonio / 0.02)) * 100;

    final double calidad =
        oxigenoScore * 0.25 +
        phScore * 0.25 +
        temperaturaScore * 0.2 +
        solidosScore * 0.15 +
        amonioScore * 0.15;

    final double purezaValor = ((500 - solidos) / 500 * 100).clamp(0, 100);
    final String pureza = purezaValor.toStringAsFixed(1);

    final String nivelPH =
        ph < 6
            ? "Ácido"
            : ph > 7.1
            ? "Básico"
            : "Neutro";
    final String nivelAmonio = "${amonio.toStringAsFixed(3)} mg/L";

    final Map<String, String> calculos = {
      "Índice de calidad": "${calidad.toStringAsFixed(1)}%",
      "Pureza estimada": "$pureza%",
      "Nivel de pH": nivelPH,
      "Nivel de Amonio": nivelAmonio,
    };

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
            Color cardColor = azul;

            if (keys[index] == "Índice de calidad") {
              if (calidad < 60) {
                cardColor = Colors.red.shade700;
              } else if (calidad < 80) {
                cardColor = Colors.yellow.shade700;
              } else {
                cardColor = Colors.green.shade700;
              }
            } else if (keys[index] == "Nivel de pH") {
              cardColor = _getCardColor(ph, 6.5, 7.5);
            } else if (keys[index] == "Nivel de Amonio") {
              cardColor = _getCardColor(amonio, 0, 0.02);
            } else if (keys[index] == "Pureza estimada") {
              cardColor = _getCardColor(solidos, 0, 200);
            }

            return Container(
              decoration: BoxDecoration(
                color: cardColor,
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
                      style: const TextStyle(
                        color: Colors.white70,
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
      ),
    );
  }

  /// Método de utilidad para parsear Strings a double
  double _parse(String? valor) {
    if (valor == null) return 0.0;
    final partes = valor.split(" ");
    return double.tryParse(partes.first) ?? 0.0;
  }

  /// Estimación heurística del amonio en mg/L
  double calcularAmonioEstimado({
    required double ph,
    required double temperatura,
    required double oxigeno,
    required double solidos,
    required double turbidez,
  }) {
    double amonio = 0.01;

    if (ph > 7.5) amonio += 0.005 * (ph - 7.5);
    if (temperatura > 25) amonio += 0.003 * (temperatura - 25);
    if (oxigeno < 5) amonio += 0.005 * (5 - oxigeno);
    if (solidos > 300) amonio += 0.002 * ((solidos - 300) / 100);
    if (turbidez > 10) amonio += 0.001 * (turbidez - 10);

    return amonio.clamp(0.0, 1.0);
  }

  Color _getCardColor(double value, double min, double max) {
    if (value < min || value > max) {
      return Colors.red.shade700;
    } else {
      return Colors.green.shade700;
    }
  }
}
