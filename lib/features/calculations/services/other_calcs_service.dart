import 'package:flutter/material.dart';

class OtherCalcsResult {
  final Map<String, String> calculos;
  final Map<String, Color> colores;

  OtherCalcsResult({required this.calculos, required this.colores});
}

class OtherCalcsService {
  static OtherCalcsResult calcular(Map<String, String> datos) {
    final oxigeno = _parse(datos["oxigeno"]);
    final ph = _parse(datos["ph"]);
    final solidos = _parse(datos["solidos_disueltos"]);
    final temperatura = _parse(datos["temperatura"]);

    final amonio = _calcularAmonio(
      ph: ph,
      temperatura: temperatura,
      oxigeno: oxigeno,
      solidos: solidos,
    );

    double scoreRango(double value, double min, double max) {
      if (value >= min && value <= max) return 100;

      double distancia;
      if (value < min) {
        distancia = (min - value) / min;
      } else {
        distancia = (value - max) / max;
      }

      return (100 * (1 - distancia)).clamp(0, 100);
    }

    final oxigenoScore = scoreRango(oxigeno, 5, 7);
    final phScore = scoreRango(ph, 6.5, 7.5);
    final temperaturaScore = scoreRango(temperatura, 20, 25);
    final solidosScore = scoreRango(solidos, 20, 50);

    final amonioScore =
        amonio <= 0.02 ? 100 : (100 * (1 - (amonio / 0.05))).clamp(0, 100);

    final calidad =
        oxigenoScore * 0.25 +
        phScore * 0.25 +
        temperaturaScore * 0.2 +
        solidosScore * 0.15 +
        amonioScore * 0.15;

    final pureza = (100 - ((solidos - 20) / 80 * 100)).clamp(0, 100);

    final nivelPH =
        ph < 6.5
            ? "Ácido"
            : ph > 7.5
            ? "Básico"
            : "Óptimo";

    final calculos = {
      "Índice de calidad": "${calidad.toStringAsFixed(1)}%",
      "Pureza estimada": "${pureza.toStringAsFixed(1)}%",
      "Nivel de pH": nivelPH,
      "Nivel de Amonio": "${amonio.toStringAsFixed(3)} mg/L",
    };

    final colores = <String, Color>{
      "Índice de calidad": _colorCalidad(calidad),
      "Pureza estimada": _colorRango(solidos, 20, 50),
      "Nivel de pH": _colorRango(ph, 6.5, 7.5),
      "Nivel de Amonio": _colorRango(amonio, 0, 0.02),
    };

    return OtherCalcsResult(calculos: calculos, colores: colores);
  }

  // ================= UTILS =================

  static double _parse(String? valor) {
    if (valor == null) return 0.0;
    return double.tryParse(valor.split(" ").first) ?? 0.0;
  }

  static double _calcularAmonio({
    required double ph,
    required double temperatura,
    required double oxigeno,
    required double solidos,
  }) {
    double amonio = 0.01;

    if (ph > 7.5) amonio += 0.005 * (ph - 7.5);
    if (temperatura > 25) amonio += 0.003 * (temperatura - 25);
    if (oxigeno < 5) amonio += 0.005 * (5 - oxigeno);
    if (solidos > 50) amonio += 0.002 * ((solidos - 50) / 50);

    return amonio.clamp(0.0, 1.0);
  }

  static Color _colorCalidad(double calidad) {
    if (calidad < 60) return Colors.red.shade700;
    if (calidad < 80) return Colors.amber.shade700;
    return Colors.green.shade700;
  }

  static Color _colorRango(double value, double min, double max) {
    if (value < min || value > max) {
      return Colors.red.shade700;
    }
    return Colors.green.shade700;
  }
}
